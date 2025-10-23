# frozen_string_literal: true

Audiences.configure do |config|
  # disable scim observation during specs so specs can enable them when they need
  config.observe_scim = false

  config.identity_class = "ExampleUser"

  config.authenticate = ->(*) { true }

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
