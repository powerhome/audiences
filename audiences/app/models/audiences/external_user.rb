# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :group_memberships, dependent: :destroy
    has_many :groups, through: :group_memberships

    if Audiences.config.identity_class
      belongs_to :identity, class_name: Audiences.config.identity_class, # rubocop:disable Rails/ReflectionClassName
                            primary_key: Audiences.config.identity_key,
                            foreign_key: :user_id,
                            optional: true,
                            inverse_of: false
    end

    scope :from_scim, ->(*scim_json) do
      where(scim_id: scim_json&.pluck("id"))
    end

    scope :matching, ->(criterion) do
      groups = (criterion.try(:groups) || criterion).values.reject(&:empty?)
      groups.reduce(self) do |scope, group|
        group_ids = Audiences::Group.where(scim_id: group.pluck("id")).pluck(:id)
        scope.where(id: Audiences::GroupMembership.where(group_id: group_ids).select(:external_user_id))
      end
    end

    scope :matching_any, ->(first, *others) do
      others.reduce(matching(first)) do |scope, criterion|
        scope.or matching(criterion)
      end
    end

    def picture_urls = [picture_url]

    def picture_urls=(urls)
      self.picture_url = urls&.first
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
        { scim_id: data["id"], user_id: data["externalId"], data: data, created_at: Time.current,
          updated_at: Time.current }
      end
      unique_by = :scim_id if connection.supports_insert_conflict_target?
      upsert_all(attrs, unique_by: unique_by) # rubocop:disable Rails/SkipsModelValidations
      where(scim_id: attrs.pluck(:scim_id))
    end

    def as_json(...)
      data.as_json(...)
    end
  end
end
