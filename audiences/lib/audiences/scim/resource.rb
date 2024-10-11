# frozen_string_literal: true

module Audiences
  module Scim
    class Resource
      attr_accessor :options, :type, :attributes, :filter

      def initialize(type:, attributes: [], filter: nil, **options)
        @type = type
        @options = options
        @attributes = ["id", "externalId", "displayName", *attributes]
        @filter = filter
      end

      def query(**options)
        options_filter = options.delete(:filter)
        ResourcesQuery.new(Scim.client, resource: self,
                                        attributes: scim_attributes,
                                        filter: merged_filter(options_filter),
                                        **@options, **options)
      end

      def all(...)
        query(...).all
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

      def merged_filter(filter)
        return @filter unless filter
        return filter unless @filter

        "(#{@filter}) and (#{filter})"
      end
    end
  end
end
