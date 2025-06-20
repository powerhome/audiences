# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
  end

  describe ".map([])" do
    it "builds contexts with the given " do
      group1, group2, group3, _group4 = create_groups(4)

      criteria = Audiences::Criterion.map(
        [
          { groups: { Departments: [{ id: group1.scim_id }] } },
          { groups: { Territories: [{ id: group2.scim_id }], Departments: [{ id: group3.scim_id }] } },
        ]
      )

      expect(criteria.size).to eql 2
      expect(criteria.first.groups).to match_array [group1]
      expect(criteria.last.groups).to match_array [group2, group3]
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
