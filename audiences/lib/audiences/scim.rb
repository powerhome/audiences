# frozen_string_literal: true

require_relative "scim/client"
require_relative "scim/safe_object"
require_relative "scim/resources_query"

module Audiences
  module Scim
    mattr_accessor :client

  module_function

    def resources(type:, **options)
      ResourcesQuery.new(client, resource_type: type, **options)
    end
  end
end
