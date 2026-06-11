# frozen_string_literal: true

module Audiences
  # LegacyStrategy encapsulates all query logic for the legacy ExternalUser and Group models
  # This strategy is used when use_configured_models is false
  class LegacyStrategy
    def active_users
      ExternalUser.active
    end

    def members_of(groups)
      ExternalUser.members_of(groups)
    end

    def find_by_ids(ids)
      ExternalUser.where(id: ids)
    end

    def find_by_identifiers(ids:, external_ids:)
      if ids.any? && external_ids.any?
        ExternalUser.where(id: ids).or(ExternalUser.where(user_id: external_ids))
      elsif ids.any?
        ExternalUser.where(id: ids)
      elsif external_ids.any?
        ExternalUser.where(user_id: external_ids)
      else
        ExternalUser.none
      end
    end

    def find_groups(resource_type, group_data)
      Group.from_scim(resource_type, *group_data).to_a
    end

    def get_users_from_context(context)
      context.extra_users_legacy
    end

    def none
      ExternalUser.none
    end

    def matching(groups)
      return ExternalUser.none if groups.empty?

      # AND logic: user must be member of at least one group from EACH resource type
      groups.group_by(&:resource_type).values.reduce(ExternalUser.all) do |scope, resource_groups|
        ExternalUser.members_of(resource_groups).merge(scope)
      end
    end
  end
end
