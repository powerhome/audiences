# frozen_string_literal: true

module Audiences
  module Scim
    class Resource
      attr_accessor :options, :type

      def initialize(type:, attributes: "id,externalId,displayName", **options)
        @type = type
        @options = options
        @options[:attributes] = attributes
      end

      def query(**options)
        ResourcesQuery.new(Scim.client, resource: self, **@options, **options)
      end
    end
  end
end
