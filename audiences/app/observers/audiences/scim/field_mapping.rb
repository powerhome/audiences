# frozen_string_literal: true

module Audiences
  module Scim
    class FieldMapping
      def initialize(object, mapping)
        @object = object
        @map = mapping
      end

      def remove(path, val)
        current = @object.send to(path)
        replace path, current - value(path, val)
      end

      def add(path, val)
        current = @object.send to(path)
        replace path, current + value(path, val)
      end

      def replace(path, val)
        @object.send :"#{to(path)}=", val
      end

    private

      def has?(...) = @map.key?(...)

      def to(path)
        case @map[path]
        in { to: to } then to
        in Symbol then @map[path]
        end
      end

      def value(path, val)
        case @map[path]
        in { find: find } then [val].flatten.pluck("value").map(&find)
        else val
        end
      end
    end
  end
end
