# frozen_string_literal: true

module Audiences
  module Scim
    autoload :Client, "audiences/scim/client"
    autoload :Resource, "audiences/scim/resource"
    autoload :ResourcesQuery, "audiences/scim/resources_query"

  module_function

    def client
      Client.new(**Audiences.config.scim)
    end

    def resource(type)
      Audiences.config.resources.fetch(type) do
        Resource.new(type: type)
      end
    end
  end
end
