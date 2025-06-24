# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validates :groups, presence: true

    def self.map(criteria)
      Array(criteria).map do |attrs|
        attrs["groups"] = attrs["groups"]&.to_h do |resource_type, groups|
          [resource_type, Audiences::Group.from_scim(resource_type, *groups).as_json]
        end
        new(attrs)
      end
    end

    def users
      @users ||= Audiences::ExternalUser.matching(self)
    end

    delegate :count, to: :users
  end
end
