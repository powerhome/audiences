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
    has_many :extra_users_configured, class_name: Audiences.config.user_model_class.to_s,
                                      through: :context_extra_users,
                                      source: :configured_user

    # Returns the active extra_users association based on the feature toggle
    # Delegates to adapter which handles all routing logic
    def extra_users
      Audiences::ConfigurableAdapter.get_users_from_context(self)
    end

    # Assigns extra_users, supporting dual-write during migration
    # Delegates to adapter which handles all routing and dual-write logic
    def extra_users=(users)
      Audiences::ConfigurableAdapter.assign_users_to_context(self, users)
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
      matching_users = calculate_matching_users

      # Apply active users scope using configured proc
      # Return relation, not array, so downstream code can continue querying
      Audiences::ConfigurableAdapter.active_audiences_users.merge(matching_users)
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

    def calculate_matching_users
      return Audiences::ConfigurableAdapter.all if match_all
      return Audiences::ConfigurableAdapter.none if criteria.empty? && extra_user_ids.empty?

      criteria_matches.or(extra_matches)
    end

    def criteria_matches
      # OR logic between criteria, AND within each criterion
      criteria.map(&:matching_users)
              .reduce(Audiences::ConfigurableAdapter.none) { |scope, criterion_scope| scope.or(criterion_scope) }
    end

    def extra_matches
      return Audiences::ConfigurableAdapter.none if extra_user_ids.empty?

      Audiences::ConfigurableAdapter.audiences_find_by_ids(extra_user_ids)
    end

    def extra_user_ids
      # Get IDs from extra_users using adapter's generic id method
      # Provider-agnostic: works with any configured identity model
      extra_users.map { |user| Audiences::ConfigurableAdapter.new(user).id }
    end
  end
end
