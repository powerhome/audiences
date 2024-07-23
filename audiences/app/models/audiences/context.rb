# frozen_string_literal: true

module Audiences
  # Represents a context where the group of users (audience) is relevant.
  # It includes the current matching users and the criteria to match these
  # users (#criteria, #match_all, #extra_users).
  #
  class Context < ApplicationRecord
    include Locating
    include ::Audiences::MembershipGroup

    belongs_to :owner, polymorphic: true
    has_many :criteria, class_name: "Audiences::Criterion",
                        autosave: true,
                        dependent: :destroy

    before_save if: :match_all do
      self.criteria = []
      self.extra_users = []
    end

    before_save do
      criteria.each(&:refresh_users!)
      self.users = ContextUsers.new(self).to_a
    end

    after_save do
      Notifications.publish(self)
    end
  end
end
