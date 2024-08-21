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
                                        attributes: scim_attributes,
                                        **@options, **options)
      end

      def scim_attributes
        @attributes.reduce([]) do |attrs, attr|
          case attr
          when Hash
            attrs + attr.map do |key, nested_attrs|
              nested_attrs.map { "#{key}.#{_1}" }
            end
          else
            attrs + [attr]
          end
        end.join(",")
      end
    end
  end
end
