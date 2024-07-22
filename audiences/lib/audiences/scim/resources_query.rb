# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Audiences
  module Scim
    class ResourcesQuery
      include Enumerable

      attr_reader :options, :resource

      def initialize(client, resource:, **options)
        @client = client
        @resource = resource
        @options = options
      end

      def all
        to_enum(:each, all: true)
      end

      def each(all: false, &block)
        resources.each(&block)
        next_page&.each(all: true, &block) if all
      end

      def resources
        @resources ||= response.fetch("Resources", [])
      end

      def next_page?
        start_index + per_page <= total_results
      end

      def start_index
        response.fetch("startIndex", 1)
      end

      def per_page
        response["itemsPerPage"].to_i
      end

      def total_results
        response["totalResults"].to_i
      end

      def next_index
        start_index + per_page
      end

      def next_page
        return unless next_page?

        ResourcesQuery.new(@client, resource: @resource, **@options, startIndex: next_index)
      end

    private

      def response
        @response ||= @client.perform_request(path: @resource.type, method: :Get, query: @options)
      end
    end
  end
end
