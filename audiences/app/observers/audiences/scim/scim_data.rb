# frozen_string_literal: true

module Audiences
  module Scim
    class ScimData
      def replace(object, key, value) = _replace(object.data || {}, key.split("."), value)

      def add(object, key, val)
        value = object.data&.dig(*key.split(".")) || []
        replace(key, [...value, val])
      end

      def remove(object, key, val)
        values = object.data&.dig(*key.split(".")) || []
        to_remove = [val].flatten.pluck("value")
        replace(key, values&.reject { |value| to_remove.include?(value["value"]) })
      end

    private

      def _replace(data, key, val)
        first_key, *rest_keys = key
        if rest_keys.empty?
          data[first_key] = val
        else
          _replace(data[first_key] ||= {}, rest_keys, val)
        end
      end
    end
  end
end
