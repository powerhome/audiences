# frozen_string_literal: true

module Audiences
  class ExternalUser < ApplicationRecord
    has_many :group_memberships, dependent: :destroy
    has_many :groups, through: :group_memberships, dependent: :destroy

    has_many :context_extra_users, class_name: "Audiences::ContextExtraUser", dependent: :destroy
    has_many :contexts, through: :context_extra_users, source: :context

    validate :required_group_types, if: :active?

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
      where(scim_id: scim_json.pluck("id").compact)
        .or(where(user_id: scim_json.pluck("externalId").compact))
    end

    scope :matching, ->(criterion) do
      return none if criterion.groups.empty?

      criterion.groups
               .group_by(&:resource_type)
               .values
               .reduce(self) do |scope, groups|
        scope.members_of(groups)
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
          "territory" => names["Territories"], "territoryAbbr" => TERRITORY_ABBRS[names["Territories"]]
        },
      }
    end

    TERRITORY_ABBRS = {
      "Philadelphia" => "PHL",
      "New Jersey" => "NJ",
      "Maryland" => "MD",
      "Connecticut" => "CT",
      "Long Island" => "LI",
      "Boston" => "BOS",
      "Atlanta" => "ATL",
      "Chicago" => "CHI",
      "Detroit" => "DET",
      "Houston" => "HOU",
      "Dallas" => "DAL",
      "Denver" => "DEN",
      "Tampa" => "TPA",
      "Austin" => "AUS",
      "Charlotte" => "CLT",
      "Nashville" => "NSH",
      "Phoenix" => "PHX",
      "Pittsburgh" => "PIT",
      "San Antonio" => "SAO",
      "Fort Lauderdale" => "FLL",
      "Las Vegas" => "LVS",
      "Orlando" => "ORL",
      "Cincinnati" => "CIN",
      "Columbus" => "CLB",
      "Jacksonville" => "JAX",
    }.freeze

  private

    def required_group_types
      expected_types = Audiences.config.required_user_group_types
      return if expected_types.blank?

      actual_types = groups.map(&:resource_type)
      missing_types = expected_types - actual_types

      return if missing_types.empty?

      errors.add(:groups, "must include groups of types: #{missing_types.join(', ')}")
    end
  end
end
