# frozen_string_literal: true

module Audiences
  # @private
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true

    has_many :criteria, class_name: "Audiences::Criterion",
                        autosave: true,
                        dependent: :destroy
    has_many :memberships, as: :group, dependent: :delete_all
    has_many :users, through: :memberships, source: :external_user, dependent: :delete_all

    before_commit :refresh_users
    after_commit :notify

    # Finds or creates a context for the given owner
    #
    # @private
    # @return [Audiences::Context]
    def self.for(owner)
      where(owner: owner).first_or_create!
    end

    # Total users within this context (see #users)
    delegate :count, to: :users

    def refresh_users
      self.users = ContextUsers.new(self).to_a
    end

  private

    def notify
      Notifications.publish(self)
    end
  end
end
