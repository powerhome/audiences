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

      # Standardize the ids to an array of strings
      ids = Array(external_ids).map(&:to_s)

      # The local database is used as a cache for SCIM users, because this is significantly faster than querying SCIM
      stored_users = Audiences::ExternalUser.where(user_id: ids)

      missing_ids = ids - stored_users.map(&:user_id)
      # If all users are already in the local database, return them without querying SCIM
      return stored_users.map(&:data) if missing_ids.empty?

      # Some users are missing from the local database, so we need to fetch them from SCIM
      missing_ids.in_groups_of(count, false).each do |batch_ids|
        filter = batch_ids.map { "externalId eq #{_1}" }.join(" OR ")
        scim_users = Audiences::Scim.resource(:Users).all(count: count, filter: filter).to_a

        next if scim_users.empty?
        # Store the missing users
        self.wrap(scim_users)
      end

      new_users = Audiences::ExternalUser.where(user_id: missing_ids).to_a
      stored_users.concat(new_users).map(&:data)
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
