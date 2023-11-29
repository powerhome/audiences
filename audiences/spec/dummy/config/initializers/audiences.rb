# frozen_string_literal: true

Audiences::Scim.client = Audiences::Scim::Client.new(
  uri: ENV.fetch("SCIM_V2_API", "http://example.com/scim/v2/"),
  headers: { "Authorization" => "Bearer 123456789" }
)

Rails.application.config.to_prepare do
  Audiences::Notifications.subscribe ExampleOwner, job: UpdateMembershipsJob
end
