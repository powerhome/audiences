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
    has_many :legacy_extra_users, class_name: "Audiences::ExternalUser",
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

    def users(groups_by_criterion: {})
      matching_external_users(groups_by_criterion).instance_exec(&Audiences.default_users_scope)
    end

    delegate :count, to: :users

    # The extra users, inactive ones included, as the source calculates them.
    def extra_users
      Audiences.source.extra_users_of(self)
    end

    def extra_users=(users)
      self.legacy_extra_users = users
    end

    def source_user_ids
      context_extra_users.map(&:source_user_id)
    end

    def as_json(...)
      groups_by_criterion = criteria.index_with { |criterion| Audiences.source.groups_of(criterion).to_a }

      {
        match_all: match_all,
        count: users(groups_by_criterion: groups_by_criterion).count,
        extra_users: Audiences.source.present(extra_users.instance_exec(&Audiences.default_users_scope)),
        criteria: groups_by_criterion.map { |criterion, groups| criterion.as_json(groups: groups) },
      }.as_json(...)
    end

  private

    def notify_subscriptions
      Notifications.publish(self)
    end

    def matching_external_users(groups_by_criterion)
      return Audiences.source.all_users if match_all

      extra_users.or(matching_criteria(groups_by_criterion))
    end

    def matching_criteria(groups_by_criterion)
      criteria = self.criteria.to_a
      return Audiences.source.all_users.none if criteria.empty?

      criteria.map { |criterion| criterion.matching_users(groups: groups_by_criterion[criterion]) }.reduce(:or)
    end
  end
end
