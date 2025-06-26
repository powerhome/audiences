# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
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
      expect(criteria.first.groups).to match({ "Departments" => [department.as_json] })
      expect(criteria.last.groups).to match({ "Territories" => [territory.as_json] })
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
