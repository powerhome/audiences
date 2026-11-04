# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :group_memberships, dependent: :destroy
    has_many :groups, through: :group_memberships, dependent: :destroy

    has_many :context_extra_users, class_name: "Audiences::ContextExtraUser", dependent: :destroy
    has_many :contexts, through: :context_extra_users, source: :context

    if Audiences.config.identity_class
      belongs_to :identity, class_name: Audiences.config.identity_class, # rubocop:disable Rails/ReflectionClassName
                            primary_key: Audiences.config.identity_key,
                            foreign_key: :user_id,
                            optional: true,
                            inverse_of: false
    end

    after_commit if: :active_previously_changed?, on: %i[create update destroy] do
      group_contexts = groups.flat_map do |group|
        Audiences::Context.relevant_to(group).to_a
      end
      match_all_contexts = Audiences::Context.where(match_all: true)

      Audiences::Notifications.publish(*[*contexts, *group_contexts, *match_all_contexts].uniq)
    end

    scope :active, -> { where(active: true) }

    scope :members_of, ->(groups) do
      where(id: Audiences::GroupMembership.where(group: groups).select(:external_user_id))
    end

    scope :search, ->(display_name) do
      where(arel_table[:display_name].matches("%#{display_name}%"))
    end

    scope :from_scim, ->(*scim_json) do
      # Flatten in case array is passed
      json_array = scim_json.flatten
      ids = json_array.filter_map { |h| h.is_a?(Hash) ? (h["id"] || h[:id]) : nil }
      external_ids = json_array.filter_map { |h| h.is_a?(Hash) ? (h["externalId"] || h[:externalId]) : nil }

      where(scim_id: ids).or(where(user_id: external_ids))
    end

    scope :matching, ->(criterion) do
      matching_criteria(Audiences::Criterion.where(id: criterion.id))
    end

    scope :matching_any, ->(*criteria) do
      matching_criteria(Audiences::Criterion.where(id: criteria.map(&:id)))
    end

    # Users matching any of the given criteria. A user matches a criterion when,
    # for each resource type among the criterion's groups, they belong to at
    # least one of its groups of that type. A criterion without groups matches
    # no one.
    #
    # The criteria, their groups, and the memberships are all read in this one
    # statement, so the database resolves them from a single snapshot: a
    # concurrent update that replaces the criteria is either fully visible or
    # not visible at all, rather than leaving some criteria resolving to none.
    #
    # @param criteria [ActiveRecord::Relation<Audiences::Criterion>]
    scope :matching_criteria, ->(criteria) { where(matching_criteria_condition(criteria)) }

    def self.matching_criteria_condition(criteria) # rubocop:disable Metrics/MethodLength
      criterion_groups = Audiences::CriterionGroup.table_name
      groups = Audiences::Group.table_name
      memberships = Audiences::GroupMembership.table_name

      <<~SQL.squish
        EXISTS (
          SELECT 1 FROM #{Audiences::Criterion.table_name} matched_criteria
          WHERE matched_criteria.id IN (#{criteria.select(:id).to_sql})
            AND EXISTS (
              SELECT 1 FROM #{criterion_groups} any_cg
              WHERE any_cg.criterion_id = matched_criteria.id
            )
            AND NOT EXISTS (
              SELECT 1 FROM #{criterion_groups} required_cg
              INNER JOIN #{groups} required_groups ON required_groups.id = required_cg.group_id
              WHERE required_cg.criterion_id = matched_criteria.id
                AND NOT EXISTS (
                  SELECT 1 FROM #{criterion_groups} member_cg
                  INNER JOIN #{groups} member_groups ON member_groups.id = member_cg.group_id
                  INNER JOIN #{memberships} memberships ON memberships.group_id = member_cg.group_id
                  WHERE member_cg.criterion_id = matched_criteria.id
                    AND memberships.external_user_id = #{table_name}.id
                    AND (member_groups.resource_type = required_groups.resource_type
                         OR (member_groups.resource_type IS NULL AND required_groups.resource_type IS NULL))
                )
            )
        )
      SQL
    end

    def picture_urls = [picture_url]

    def picture_urls=(urls)
      self.picture_url = urls&.first
    end

    def as_json(...)
      as_scim.slice(*Audiences.exposed_user_attributes)
    end

    def as_scim(...)
      (data || {}).merge(groups_as_scim)
    end

    def groups_as_scim
      names = groups.reduce({}) { |nam, group| nam.merge(group.resource_type => group.display_name) }

      {
        "groups" => groups.map { |g| { "value" => g.scim_id, "display" => g.display_name } },
        "title" => names["Titles"],
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
          "role" => names["Roles"], "department" => names["Departments"],
          "territory" => names["Territories"], "territoryAbbr" => territory_abbr(names["Territories"])
        },
      }
    end

    def missing_group_types(expected_types = Audiences.config.required_group_types)
      return [] if expected_types.blank?

      actual_types = groups.map(&:resource_type)
      expected_types - actual_types
    end

  private

    def territory_abbr(territory)
      Audiences.config.territory_abbreviations[territory]
    end
  end
end
