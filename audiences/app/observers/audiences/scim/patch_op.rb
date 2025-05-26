# frozen_string_literal: true

module Audiences
  module Scim
    class PatchOp
      attr_reader :operations

      def initialize(patch_op)
        @operations = patch_op["Operations"].flat_map do |operation|
          derive_operation(operation)
        end
      end

      def process(resource, mapping)
        field_mapping = FieldMapping.new(resource, mapping)
        @operations.each { _1.process(field_mapping) }
      end

      def process!(resource, mapping)
        process(resource, mapping)
        resource.save!
      end

    private

      Operation = Struct.new(:op, :path, :value) do
        def process(mapping)
          raise "Unknown operation #{op}" unless mapping.respond_to?(op)

          mapping.public_send(op, path, value)
        end
      end

      def derive_operation(operation)
        case operation["value"]
        when Hash
          operation["value"].flat_map do |key, value|
            derive_operation("op" => operation["op"],
                             "path" => [operation["path"], key].compact.join("."),
                             "value" => value)
          end
        else
          [Operation.new(operation["op"], operation["path"], operation["value"])]
        end
      end
    end
  end
end
