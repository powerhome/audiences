# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
  end

  describe "validations" do
    it "does not allow criterion groups with empty groups" do
      criterion = Audiences::Criterion.new(groups: [])
      expect(criterion).not_to be_valid
      expect(criterion.errors[:groups]).to include("can't be blank")
    end
  end

  describe ".relevant_to" do
    it "returns criteria relevant to the given group" do
      group1, group2 = create_groups(2)
      criterion1 = create_criterion(groups: [group1])
      criterion2 = create_criterion(groups: [group2])
      criterion3 = create_criterion(groups: [group1, group2])
      create_criterion(groups: [])

      expect(Audiences::Criterion.relevant_to(group1)).to match_array [criterion1, criterion3]
      expect(Audiences::Criterion.relevant_to(group2)).to match_array [criterion2, criterion3]
    end
  end

  describe ".map([])" do
    it "builds contexts with the given " do
      department = create_group(resource_type: "Departments")
      territory = create_group(resource_type: "Territories")

      criteria = Audiences::Criterion.map(
        [
          { "groups" => { "Departments" => [department.as_json] } },
          { "groups" => { "Territories" => [territory.as_json] } },
        ]
      )

      expect(criteria.size).to eql 2
      expect(criteria.first.groups).to match_array [department]
      expect(criteria.last.groups).to match_array [territory]
    end

    it "allows setting creating groups not matching the default group scope" do
      department = create_group(resource_type: "Departments", scim_id: "123", active: false)

      criteria = Audiences::Criterion.map(
        [
          { "groups" => { "Departments" => [department.as_json] } },
        ]
      )

      expect(criteria.size).to eql 1
      expect(criteria.first.groups).to match_array([department])
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
