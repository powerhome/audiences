# frozen_string_literal: true

Audiences.scim = Audiences::Scim.new(
  uri: ENV.fetch("SCIM_V2_API", "http://example.com/scim/v2/"),
  headers: { "Authorization" => "Bearer 123456789" }
)
