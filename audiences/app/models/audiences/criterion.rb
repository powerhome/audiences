# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validates :groups, presence: true

    has_many :criterion_groups, autosave: true, dependent: :destroy
    has_many :groups, through: :criterion_groups

    scope :relevant_to, ->(group) do
      joins(:criterion_groups).where(criterion_groups: { group: group })
    end

    # Maps an array of attribute hashes to Criterion objects.
    #
    # Each attribute hash should have a :groups key, whose value is a hash
    # mapping resource types (e.g., "Departments", "Territories") to arrays of group hashes,
    # each containing an :id key (the SCIM group ID).
    #
    # Example input:
    #
    #   [
    #     { groups: { Departments: [{ id: "1" }] } },
    #     { groups: { Territories: [{ id: "2" }], Departments: [{ id: "3" }] } },
    #   ]
    #
    # Returns an array of new Criterion objects, each initialized with the corresponding group criterion.
    #
    # @param [Array<Hash>] criteria Array of attribute hashes describing groups
    # @return [Array<Criterion>] Array of Criterion objects
    def self.map(criteria)
      Array(criteria).map do |attrs|
        groups = attrs["groups"]&.flat_map do |resource_type, scim_groups|
          Audiences::Group.from_scim(resource_type, *scim_groups).to_a
        end
        new(groups: groups)
      end
    end

    def as_json(...)
      groups = self.groups.group_by(&:resource_type)

      { id: id, count: count, groups: groups }.as_json(...)
    end

    def users
      adapter_class = Audiences::ConfigurableAdapter
      matching_users = matching_users(adapter_class)
      # Return relation, not array, so downstream code can continue querying
      adapter_class.active_audiences_users.merge(matching_users)
    end

    def matching_users(adapter_class)
      return adapter_class.none if groups.empty?
      
      # AND logic: user must be member of at least one group from EACH resource type
      groups.group_by(&:resource_type).values.reduce(adapter_class.all) do |scope, resource_groups|
        adapter_class.audiences_members_of(resource_groups).merge(scope)
      end
    end

    delegate :count, to: :users
  end
end
