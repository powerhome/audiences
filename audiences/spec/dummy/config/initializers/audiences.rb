# frozen_string_literal: true

Audiences.configure do |config|
  config.scim = {
    uri: ENV.fetch("SCIM_V2_API", "http://example.com/scim/v2/"),
    headers: { "Authorization" => ENV.fetch("SCIM_AUTHORIZATION", "Bearer 123456789") },
  }

  config.subscriptions do
    subscribe ExampleOwner, job: UpdateMembershipsJob
  end
end
