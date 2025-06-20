# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validates :groups, presence: true

    has_many :criterion_groups
    has_many :groups, through: :criterion_groups

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
      Audiences::ExternalUser.matching(self)
                             .instance_exec(&Audiences.default_users_scope)
    end

    delegate :count, to: :users
  end
end
