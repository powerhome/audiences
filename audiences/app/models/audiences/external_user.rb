# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    if Audiences.config.identity_class
      belongs_to :identity, class_name: Audiences.config.identity_class, # rubocop:disable Rails/ReflectionClassName
                            primary_key: Audiences.config.identity_key,
                            foreign_key: :user_id,
                            optional: true,
                            inverse_of: false
    end

    def self.fetch(external_ids, count: 100)
      return [] unless external_ids.any?

      Array(external_ids).in_groups_of(count, false).flat_map do |ids|
        filter = Array(ids).map { "externalId eq #{_1}" }.join(" OR ")
        Audiences::Scim.resource(:Users).all(count: count, filter: filter).to_a
      end
    end

    def self.wrap(resources)
      return [] unless resources&.any?

      attrs = resources.map do |data|
        { user_id: data["externalId"], data: data, created_at: Time.current, updated_at: Time.current }
      end
      unique_by = :user_id if connection.supports_insert_conflict_target?
      upsert_all(attrs, unique_by: unique_by) # rubocop:disable Rails/SkipsModelValidations
      where(user_id: attrs.pluck(:user_id))
    end

    def as_json(...)
      data.as_json(...)
    end
  end
end
