# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    include ::Audiences::MembershipGroup

    belongs_to :context, class_name: "Audiences::Context"

    def self.map(criteria)
      Array(criteria).map { new(_1) }
    end

    def refresh_users!
      update!(
        users: CriterionUsers.new(groups || {}).to_a,
        refreshed_at: Time.current
      )
    end
  end
end
