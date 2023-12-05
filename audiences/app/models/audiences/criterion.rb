# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    has_many :memberships, as: :group, dependent: :delete_all
    has_many :users, through: :memberships, source: :external_user, dependent: :delete_all

    def self.map(criteria)
      Array(criteria).map { new(_1) }
    end

    delegate :count, to: :users

    def refresh_users
      self.users = CriterionUsers.new(groups || {}).to_a
      self.refreshed_at = Time.current
    end
  end
end
