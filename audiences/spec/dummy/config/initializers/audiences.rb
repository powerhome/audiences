# frozen_string_literal: true

Audiences.configure do |config|
  # disable scim observation during specs so specs can enable them when they need
  config.observe_scim = false

  config.identity_class = "ExampleUser"

  config.authenticate = ->(*) { true }

  # Configure adapter for testing
  config.user_model_class = "ConfiguredUser"
  config.group_model_class = "ConfiguredGroup"

  # Feature toggles - default to legacy mode for backward compatibility
  # Individual tests can enable configured models as needed
  config.use_configured_models = false
  config.dual_write_extra_users = true

  config.to_audiences_hash_proc = ->(user) {
    {
      id: user.id,
      external_id: user.user_id,
      display_name: user.display_name,
      active: user.active,
      data: user.respond_to?(:data) ? user.data : {},
      groups: if user.respond_to?(:groups)
                user.groups.map do |g|
                  {
                    id: g.id,
                    display_name: g.display_name,
                    resource_type: g.respond_to?(:resource_type) ? g.resource_type : "Group",
                  }
                end
              else
                []
              end,
    }
  }

  config.active_users_scope_proc = ->(relation) {
    relation.where(active: true)
  }

  config.members_of_scope_proc = ->(relation, groups) {
    relation.members_of(groups)
  }

  # rubocop:disable Rails/DynamicFindBy - false positive, this is a config attribute not a finder
  config.find_by_ids_proc = ->(relation, ids) {
    relation.where(id: ids)
  }
  # rubocop:enable Rails/DynamicFindBy

  config.find_groups_proc = ->(resource_type, group_data) {
    ids = group_data.filter_map { |h| h["id"] }
    external_ids = group_data.filter_map { |h| h["externalId"] }

    query = ConfiguredGroup.where(resource_type: resource_type)
    return query.none if ids.empty? && external_ids.empty?

    # Use [nil] for empty arrays to avoid ActiveRecord returning all records
    query.where(id: ids.presence || [nil])
         .or(query.where(external_id: external_ids.presence || [nil]))
  }

  config.notifications do
    subscribe ExampleOwner, job: UpdateMembershipsJob
  end

  config.exposed_user_attributes = [
    "id",
    "externalId",
    "displayName",
    "photos",
    "title",
    "groups",
    "urn:ietf:params:scim:schemas:extension:authservice:2.0:User",
  ]
end
