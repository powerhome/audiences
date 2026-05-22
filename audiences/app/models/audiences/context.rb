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
    has_many :extra_users, class_name: "Audiences::ExternalUser",
                           through: :context_extra_users,
                           source: :external_user

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
      scoped_users = adapter_class.active_audiences_users.merge(matching_users)
      
      # Wrap in adapters to provide ExternalUser-like interface
      scoped_users.map { |record| adapter_class.new(record) }
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
      return adapter_class.none if criteria.empty? && extra_user_scim_ids.empty?
      
      # Match criteria (OR logic between criteria, AND within each criterion)
      criteria_matches = criteria.map { |criterion| criterion.matching_users(adapter_class) }
                                 .reduce(adapter_class.none) { |scope, criterion_scope| scope.or(criterion_scope) }
      
      # Match extra users
      extra_matches = extra_user_scim_ids.any? ?
        adapter_class.audiences_find_by_scim_ids(extra_user_scim_ids) :
        adapter_class.none
      
      criteria_matches.or(extra_matches)
    end
    
    def extra_user_scim_ids
      # Get SCIM IDs from extra_users association (still using old ExternalUser for now)
      extra_users.pluck(:scim_id)
    end

    # Legacy methods - keeping for now during transition
    def matching_external_users
      match_all ? ExternalUser.all : matching_extra_users.or(matching_criteria)
    end

    def matching_extra_users
      ExternalUser.where(id: extra_users.select(:id))
    end

    def matching_criteria
      criteria.any? ? ExternalUser.matching_any(*criteria) : ExternalUser.none
    end
  end
end
