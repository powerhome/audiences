# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Audiences
  module Scim
    class ResourcesQuery
      include Enumerable

      attr_reader :query_options

      def initialize(client, resource_type:, wrapper: SafeObject, **query_options)
        @client = client
        @wrapper = wrapper
        @resource_type = resource_type
        @query_options = query_options
      end

      def all
        to_enum(:each, all: true)
      end

      def each(all: false, &block)
        resources.each(&block)
        next_page&.each(all: true, &block) if all
      end

      def resources
        @resources ||= @wrapper.wrap(response.fetch("Resources", []))
      end

      def next_page?
        start_index = response.fetch("startIndex", 1)
        per_page = response["itemsPerPage"].to_i
        total_results = response["totalResults"].to_i

        start_index + per_page <= total_results
      end

      def next_page
        return unless next_page?

        current_page = @query_options.fetch(:page, 1)
        ResourcesQuery.new(@client, wrapper: @wrapper, resource_type: @resource_type, **@query_options,
                                    page: current_page + 1)
      end

    private

      def response
        @response ||= @client.perform_request(path: @resource_type, method: :Get, query: @query_options)
      end
    end
  end
end
