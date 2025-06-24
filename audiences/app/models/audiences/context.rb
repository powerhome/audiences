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
      matching_external_users.instance_exec(&Audiences.default_users_scope)
    end

    delegate :count, to: :users

    def as_json(...)
      {
        match_all: match_all,
        count: count,
        extra_users: extra_users,
        criteria: criteria,
      }.as_json(...)
    end

  private

    def notify_subscriptions
      Notifications.publish(self)
    end

    def matching_external_users
      return ExternalUser.all if match_all

      criteria_scope = criteria.any? ? ExternalUser.matching_any(*criteria) : ExternalUser.none
      ExternalUser.where(id: extra_users.select(:id)).or(criteria_scope)
    end
  end
end
