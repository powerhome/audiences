# frozen_string_literal: true

module Audiences
  # @private
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true

    has_many :criteria, class_name: "Audiences::Criterion",
                        autosave: true,
                        dependent: :destroy

    after_commit :notify

    # Finds or creates a context for the given owner
    #
    # @private
    # @return [Audiences::Context]
    def self.for(owner)
      where(owner: owner).first_or_create!
    end

    def count
      users.size
    end

    def users
      [*extra_users, *criteria.flat_map(&:users)].uniq.compact
    end

  private

    def notify
      Audiences::Notifications.publish(self)
    end
  end
end
