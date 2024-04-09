# frozen_string_literal: true

require_relative "scim/client"
require_relative "scim/safe_object"
require_relative "scim/resources_query"

module Audiences
  module Scim
    mattr_accessor :client
    mattr_accessor :defaults, default: Hash.new(attributes: "id,displayName")

  module_function

    def resources(type:, client: Scim.client, **options)
      options = defaults.fetch(type, {}).merge(options)

      ResourcesQuery.new(client, resource_type: type, **options)
    end
  end
end
