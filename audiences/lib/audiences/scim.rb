# frozen_string_literal: true

require_relative "scim/client"
require_relative "scim/resources_query"

module Audiences
  module Scim
    mattr_accessor :defaults, default: Hash.new(attributes: "id,externalId,displayName")

  module_function

    def client
      Client.new(**Audiences.config.scim)
    end

    def query(type:, client: Scim.client, **options)
      options = (defaults[type] || {}).merge(options)

      ResourcesQuery.new(client, resource_type: type, **options)
    end
  end
end
