# frozen_string_literal: true

module Audiences
  # Represents a context where the group of users (audience) is relevant.
  # It includes the current matching users and the criteria to match these
  # users (#criteria, #match_all, #extra_users).
  #
  class Context < ApplicationRecord
    include Locating

    belongs_to :owner, polymorphic: true
    has_many :criteria, class_name: "Audiences::Criterion",
                        autosave: true,
                        dependent: :destroy

    has_many :context_extra_users, class_name: "Audiences::ContextExtraUser"
    
    # Association to ExternalUser model (original SCIM-based identity)
    has_many :extra_users_legacy, class_name: "Audiences::ExternalUser",
                                  through: :context_extra_users,
                                  source: :external_user
    
    # Association to configured identity model
    has_many :extra_users_configured, class_name: "ConfiguredUser",
                                      through: :context_extra_users,
                                      source: :configured_user
    
    # Returns the active extra_users association based on the feature toggle
    def extra_users
      return extra_users_configured if Audiences.config.use_configured_models
      
      extra_users_legacy
    end
    
    # Assigns extra_users, supporting dual-write during migration
    # Accepts user model instances from the configured user_model_class
    # During dual-write, also populates legacy ExternalUser association for backwards compatibility
    def extra_users=(users)
      if users.blank?
        context_extra_users.destroy_all
        return
      end
      
      if Audiences.config.dual_write_extra_users
        # Dual-write mode: populate both foreign keys for safe migration
        write_with_dual_foreign_keys(users)
      elsif Audiences.config.use_configured_models
        # Configured-only mode
        self.extra_users_configured = users
      else
        # Legacy-only mode
        self.extra_users_legacy = users
      end
    end

    scope :relevant_to, ->(group) do
      joins(:criteria).merge(Criterion.relevant_to(group))
    end

    before_save if: :match_all do
      self.criteria = []
      self.extra_users = []
    end

    after_commit :notify_subscriptions, on: :update

    def users
      adapter_class = Audiences::ConfigurableAdapter
      matching_users = calculate_matching_users(adapter_class)

      # Apply active users scope using configured proc
      # Return relation, not array, so downstream code can continue querying
      adapter_class.active_audiences_users.merge(matching_users)
    end

    delegate :count, to: :users

    def as_json(...)
      {
        match_all: match_all,
        count: count,
        extra_users: extra_users.instance_exec(&Audiences.default_users_scope),
        criteria: criteria,
      }.as_json(...)
    end

  private

    def notify_subscriptions
      Notifications.publish(self)
    end

    def calculate_matching_users(adapter_class)
      return adapter_class.all if match_all
      return adapter_class.none if criteria.empty? && extra_user_ids.empty?

      # Match criteria (OR logic between criteria, AND within each criterion)
      criteria_matches = criteria.map { |criterion| criterion.matching_users(adapter_class) }
                                 .reduce(adapter_class.none) { |scope, criterion_scope| scope.or(criterion_scope) }

      # Match extra users
      extra_matches = extra_user_ids.any? ?
        adapter_class.audiences_find_by_ids(extra_user_ids) :
        adapter_class.none

      criteria_matches.or(extra_matches)
    end

    def extra_user_ids
      # Get IDs from extra_users using adapter's generic id method
      # Provider-agnostic: works with any configured identity model
      extra_users.map { |user| Audiences::ConfigurableAdapter.new(user).id }
    end
    
    # Writes to both foreign key columns during dual-write
    # Accepts configured user model instances and finds matching ExternalUser records
    # Populates both foreign keys for safe rollback capability during migration
    def write_with_dual_foreign_keys(users)
      # Extract user_ids from configured user model records
      user_ids = users.map(&:user_id)
      
      # Find matching ExternalUser records by user_id for backwards compatibility
      legacy_map = Audiences::ExternalUser.where(user_id: user_ids).index_by(&:user_id)
      
      # Clear existing join records
      context_extra_users.destroy_all
      
      # Create join records with BOTH primary keys
      users.each do |configured_user|
        legacy_user = legacy_map[configured_user.user_id]
        
        context_extra_users.create!(
          external_user_id: legacy_user&.id,      # Legacy ExternalUser PK (or nil if missing)
          configured_user_id: configured_user.id  # Primary configured model PK
        )
      end
    end
  end
end
