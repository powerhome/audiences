# frozen_string_literal: true

Audiences.scim = Audiences::Scim.new(
  uri: "http://scim-stub:3002/api/scim/v2/",
  headers: { "Authorization" => "Bearer 123456789" }
)
