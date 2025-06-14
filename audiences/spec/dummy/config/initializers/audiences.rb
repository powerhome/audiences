# frozen_string_literal: true

Audiences.configure do |config|
  # disable scim observation during specs so specs can enable them when they need
  config.observe_scim = false

  config.identity_class = "ExampleUser"

  config.authenticate = ->(*) { true }

  config.scim = {
    uri: ENV.fetch("SCIM_V2_API", "http://example.com/scim/v2/"),
    headers: { "Authorization" => ENV.fetch("SCIM_AUTHORIZATION", "Bearer 123456789") },
  }

  config.notifications do
    subscribe ExampleOwner, job: UpdateMembershipsJob
  end
end
