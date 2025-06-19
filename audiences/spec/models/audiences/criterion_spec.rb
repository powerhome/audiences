# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
  end

  describe ".with_group" do
    it "matches all criterion that includes the given group" do
      group = create_group(resource_type: "Territories")
      owner = ExampleOwner.create
      context = Audiences::Context.create!(
        owner: owner,
        criteria: Audiences::Criterion.map([
          { groups: { Territories: [{ id: group.scim_id }], Departments: [{ id: 2 }] } },
          { groups: { Territories: [{ id: 3 }], Departments: [{ id: 4 }] } },
          { groups: { Territories: [{ id: group.scim_id }], Departments: [{ id: 6 }] } },
        ])
      )
      criterion1, criterion2, criterion3 = context.criteria

      matching = Audiences::Criterion.with_group(group)

      expect(matching).to match_array([criterion1, criterion3])
    end
  end

  describe ".map([])" do
    it "builds contexts with the given " do
      criteria = Audiences::Criterion.map(
        [
          { groups: { Departments: [{ id: 1 }] } },
          { groups: { Territories: [{ id: 3 }] } },
        ]
      )

      expect(criteria.size).to eql 2
      expect(criteria.first.groups).to match({ "Departments" => [{ "id" => 1 }] })
      expect(criteria.last.groups).to match({ "Territories" => [{ "id" => 3 }] })
    end
  end

  describe "#count" do
    it "is the count of member users" do
      users = create_users(2)
      criterion = Audiences::Criterion.new
      allow(criterion).to receive(:users) { users }

      expect(criterion.count).to eql 2
    end
  end
end
