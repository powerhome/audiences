# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validates :groups, presence: true

    scope :with_group, ->(group) do
      args = case connection.adapter_name
             when /postgres/i then ["jsonb_path_exists(groups, format('$.\"%s\"[*] ? (@.id == \"%s\")', ?, ?))", group.resource_type]
             when /mysql/i then ["JSON_CONTAINS(JSON_EXTRACT(`groups`, ?), JSON_OBJECT('id', ?))", "$.#{group.resource_type}"]
             else raise Audiences::UnsupportedAdapter, connection.adapter_name
             end

      where(*args, group.scim_id)
    end

    def self.map(criteria)
      Array(criteria).map { new(_1) }
    end

    def users
      @users ||= Audiences::ExternalUser.matching(self)
    end

    delegate :count, to: :users
  end
end
