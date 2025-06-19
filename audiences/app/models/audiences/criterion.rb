# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validates :groups, presence: true

    scope :with_group, ->(group) do
      args = case connection.adapter_name
             when /postgres/i
               ["jsonb_path_exists(groups, ?)", "$.#{group.resource_type}[*] ? (@.id == \"#{group.scim_id}\")"]
             when /mysql/i
               [
                 "JSON_CONTAINS(JSON_EXTRACT(`groups`, ?), JSON_OBJECT('id', ?))",
                 "$.#{group.resource_type}",
                 group.scim_id,
               ]
             else
               raise Audiences::UnsupportedAdapter, connection.adapter_name
             end

      where(*args)
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
