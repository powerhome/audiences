# frozen_string_literal: true

module Audiences
  module Scim
    class FieldMapping
      def initialize(mapping)
        @map = mapping
      end

      def remove(object, path, val)
        current = object.send to(path)
        replace object, path, current - value(path, val)
      end

      def add(object, path, val)
        current = object.send to(path)
        replace object, path, current + value(path, val)
      end

      def replace(object, path, val)
        object.send :"#{to(path)}=", val if @map[path]
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
