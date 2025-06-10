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

    before_save if: :match_all do
      self.criteria = []
      self.extra_users = []
    end

    after_commit :notify_subscriptions

    def users
      @users ||= matching_external_users
    end

    delegate :count, to: :users

  private

    def notify_subscriptions
      Notifications.publish(self)
    end

    def matching_external_users
      return ExternalUser.all if match_all

      criteria_scope = criteria.any? ? ExternalUser.matching_any(*criteria) : ExternalUser.none
      ExternalUser.from_scim(*extra_users).or(criteria_scope)
    end
  end
end
