# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"
    validate :must_have_groups

    has_many :criterion_groups, autosave: true, dependent: :destroy

    # Legacy association to Audiences::Group
    has_many :groups_legacy, class_name: "Audiences::Group",
                             through: :criterion_groups,
                             source: :group

    # Configured group association
    # rubocop:disable Rails/ReflectionClassName - intentionally dynamic for adapter pattern
    has_many :groups_configured, class_name: Audiences.config.group_model_class,
                                 through: :criterion_groups,
                                 source: :configured_group
    # rubocop:enable Rails/ReflectionClassName

    # Returns the active groups association based on feature toggle
    def groups
      return groups_configured if Audiences.config.use_configured_models

      groups_legacy
    end

    scope :relevant_to, ->(group) do
      if Audiences.config.use_configured_models
        joins(:criterion_groups).where(criterion_groups: { configured_group_id: group.id })
      else
        joins(:criterion_groups).where(criterion_groups: { group_id: group.id })
      end
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
        # Use adapter to find groups - it handles routing to configured or legacy models
        found_groups = attrs["groups"]&.flat_map do |resource_type, group_data|
          Audiences::ConfigurableAdapter.find_groups(resource_type, group_data)
        end

        # Assign to the appropriate association based on configuration
        if Audiences.config.use_configured_models
          new(groups_configured: found_groups)
        else
          new(groups_legacy: found_groups)
        end
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

  private

    def must_have_groups
      errors.add(:base, "must have at least one group") if groups.empty?
    end
  end
end
