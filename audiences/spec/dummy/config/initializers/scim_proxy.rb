# frozen_string_literal: true

require "audiences/scim_proxy"

Audiences::ScimProxy.config = {
  uri: "http://scim-stub:3002/api/scim/v2/",
  debug: $stdout,
}
