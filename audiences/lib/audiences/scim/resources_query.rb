# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Audiences
  module Scim
    class ResourcesQuery
      include Enumerable

      def initialize(client, resource_type:, wrapper: SafeObject, **query_options)
        @client = client
        @wrapper = wrapper
        @resource_type = resource_type
        @query_options = query_options
      end

      def each(&block)
        resources.each(&block)
      end

      def resources
        @resources ||= response.fetch("Resources", [])
                               .lazy.map { @wrapper.new(_1) }
      end

    private

      def response
        @response ||= @client.perform_request(path: @resource_type, method: :Get, query: @query_options)
      end
    end
  end
end
