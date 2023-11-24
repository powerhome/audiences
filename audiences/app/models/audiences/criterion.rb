# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"

    before_create :refresh_users

    def self.map(criteria)
      Array(criteria).map { new(_1) }
    end

    def count
      users&.size.to_i
    end

    def refresh_users
      self.users = CriterionUsers.new(groups || {})
      self.refreshed_at = Time.current
    end
  end
end
