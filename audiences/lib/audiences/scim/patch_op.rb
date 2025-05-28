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

      def process(object, operator)
        @operations.each { _1.process(object, operator) }
      end

    private

      Operation = Struct.new(:op, :path, :value) do
        def process(object, operator)
          raise "Operation #{op} is unknown to #{operator.class}" unless operator.respond_to?(op)

          operator.public_send(op, object, path, value)
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
