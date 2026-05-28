# frozen_string_literal: true

Audiences.configure do |config|
  # disable scim observation during specs so specs can enable them when they need
  config.observe_scim = false

  config.identity_class = "ExampleUser"

  config.authenticate = ->(*) { true }

  # Configure adapter to use existing ExternalUser/Group models for testing
  # Using string class names to avoid load order issues
  config.user_model_class = "Audiences::ExternalUser"
  config.group_model_class = "Audiences::Group"

  config.to_audiences_hash_proc = ->(user) {
    {
      id: user.scim_id,
      external_id: user.user_id,           # ExternalUser has user_id, not external_id
      display_name: user.display_name,
      active: user.active,
      data: user.data || {},
      groups: user.groups.map { |g|
        {
          id: g.scim_id,
          display_name: g.display_name,
          resource_type: g.resource_type
        }
      }
    }
  }

  config.active_users_scope_proc = ->(relation) {
    relation.where(active: true)
  }

  config.members_of_scope_proc = ->(relation, groups) {
    relation.members_of(groups)
  }

  config.find_by_ids_proc = ->(relation, ids) {
    relation.where(scim_id: ids)
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
