# frozen_string_literal: true

module Audiences
  module Scim
    class Resource
      attr_accessor :options, :type, :attributes

      def initialize(type:, attributes: [], **options)
        @type = type
        @options = options
        @attributes = ["id", "externalId", "displayName", *attributes]
      end

      def query(**options)
        ResourcesQuery.new(Scim.client, resource: self,
                                        attributes: @attributes.join(","),
                                        **@options, **options)
      end
    end
  end
end
