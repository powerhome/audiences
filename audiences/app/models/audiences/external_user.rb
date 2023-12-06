# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :memberships

    def self.wrap(data)
      data&.map { self.for(_1) }
    end

    def self.for(data)
      where(user_id: data["id"]).first_or_initialize.tap do |user|
        user.data = data
        user.save
      end
    end

    def as_json(*)
      data.as_json
    end
  end
end
