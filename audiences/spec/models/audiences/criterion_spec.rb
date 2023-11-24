# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
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
    it "is the count of chached users matching" do
      criteria = Audiences::Criterion.new(users: [{ id: 1 }, { id: 2 }])

      expect(criteria.count).to eql 2
    end
  end

  describe "#refresh_users" do
    it "refetches automatically when creating a new criterion" do
      stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 123")
        .to_return(status: 200, body: { "Resources" => [{ "id" => 13 }] }.to_json)

      owner = ExampleOwner.create
      context = Audiences::Context.create(owner: owner)
      criterion = context.criteria.create!(groups: { Departments: [{ id: 123 }] })

      expect(criterion.users.size).to eq 1
      expect(criterion.users.first["id"]).to eq 13
    end

    it "refetches the users matching from SCIM" do
      stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 123")
        .to_return(status: 200, body: { "Resources" => [{ "id" => 13 }] }.to_json)

      criterion = Audiences::Criterion.new(
        groups: { Departments: [{ id: 123 }] }
      )
      criterion.refresh_users

      expect(criterion.users.size).to eq 1
      expect(criterion.users.first["id"]).to eq 13
    end

    it "sets the refresh time" do
      criterion = Audiences::Criterion.new

      expect(criterion.refreshed_at).to be_nil

      criterion.refresh_users

      expect(criterion.refreshed_at).to be_a Time
    end
  end
end
