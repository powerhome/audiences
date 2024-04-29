# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :memberships

    def self.wrap(resources)
      return [] if resources.blank?

      attrs = resources.map do |data|
        { user_id: data["id"], data: data, created_at: Time.current, updated_at: Time.current }
      end
      upsert_all(attrs) # rubocop:disable Rails/SkipsModelValidations
      where(user_id: attrs.pluck(:user_id))
    end

    def as_json(*)
      data.as_json
    end
  end
end
