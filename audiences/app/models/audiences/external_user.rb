# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :memberships

    def self.wrap(resources)
      return [] unless resources&.any?

      attrs = resources.map do |data|
        { user_id: data["externalId"], data: data, created_at: Time.current, updated_at: Time.current }
      end
      unique_by = :user_id if connection.supports_insert_conflict_target?
      upsert_all(attrs, unique_by: unique_by) # rubocop:disable Rails/SkipsModelValidations
      where(user_id: attrs.pluck(:user_id))
    end

    def as_json(*)
      data.as_json
    end
  end
end
