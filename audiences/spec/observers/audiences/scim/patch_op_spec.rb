# frozen_string_literal: true

require "rails_helper"

ExampleResource = Struct.new(:display_name, :external_id, :users, keyword_init: true)

RSpec.describe Audiences::Scim::PatchOp do
  def build_op(op:, value:, path: nil) # rubocop:disable Naming/MethodParameterName
    { "op" => op, "path" => path, "value" => value }.compact
  end

  def build_patch_op(*operations)
    Audiences::Scim::PatchOp.new("Operations" => operations)
  end

  describe "#operations" do
    it "includes all operations" do
      patch_op = build_patch_op(
        build_op(op: "replace", path: "displayName", value: "New Name"),
        build_op(op: "add", path: "members", value: [{ "value" => "1" }]),
        build_op(op: "remove", path: "members", value: [{ "value" => "2" }])
      )

      expect(patch_op.operations.size).to eql 3

      expect(patch_op.operations[0].op).to eql "replace"
      expect(patch_op.operations[0].path).to eql "displayName"
      expect(patch_op.operations[0].value).to eql "New Name"

      expect(patch_op.operations[1].op).to eql "add"
      expect(patch_op.operations[1].path).to eql "members"
      expect(patch_op.operations[1].value).to eql [{ "value" => "1" }]

      expect(patch_op.operations[2].op).to eql "remove"
      expect(patch_op.operations[2].path).to eql "members"
      expect(patch_op.operations[2].value).to eql [{ "value" => "2" }]
    end

    it "derives nested attributes in the resource" do
      patch_op = build_patch_op(build_op(op: "replace", value: { "name" => { "givenName" => "Sir John" } }))

      expect(patch_op.operations.size).to eql 1
      expect(patch_op.operations.first.op).to eql "replace"
      expect(patch_op.operations.first.path).to eql "name.givenName"
      expect(patch_op.operations.first.value).to eql("Sir John")
    end

    it "derives nested attribute paths in the resource" do
      patch_op = build_patch_op(build_op(op: "replace", path: "name", value: { "givenName" => "Sir John" }))

      expect(patch_op.operations.size).to eql 1
      expect(patch_op.operations.first.op).to eql "replace"
      expect(patch_op.operations.first.path).to eql "name.givenName"
      expect(patch_op.operations.first.value).to eql("Sir John")
    end
  end

  describe "#process" do
    it "calls the operator methods corresponding to the Patch Op" do
      patch_op = build_patch_op(
        build_op(op: "replace", path: "displayName", value: "New Name"),
        build_op(op: "add", path: "members", value: [{ "value" => "1" }]),
        build_op(op: "remove", path: "members", value: [{ "value" => "2" }])
      )
      object = double("patched object")
      operator = double("patch operator", replace: nil, add: nil, remove: nil, barel_roll: nil)

      patch_op.process(object, operator)

      expect(operator).to have_received(:replace).with(object, "displayName", "New Name")
      expect(operator).to have_received(:add).with(object, "members", [{ "value" => "1" }])
      expect(operator).to have_received(:remove).with(object, "members", [{ "value" => "2" }])
    end
  end
end
