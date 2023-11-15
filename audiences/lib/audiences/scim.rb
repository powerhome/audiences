# frozen_string_literal: true

require_relative "scim/client"
require_relative "scim/safe_object"

module Audiences
  module Scim
    mattr_accessor :client
  end
end
