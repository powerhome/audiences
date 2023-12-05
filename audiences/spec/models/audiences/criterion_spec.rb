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
    it "is the count of member users" do
      owner = ExampleOwner.create
      context = Audiences::Context.create!(owner: owner)
      criteria = context.criteria.create!
      criteria.users.create(user_id: 1)
      criteria.users.create(user_id: 2)

      expect(criteria.count).to eql 2
    end
  end

  describe "#refresh_users!" do
    let(:owner) { ExampleOwner.create }
    let(:context) { Audiences::Context.for(owner) }

    it "fetches automatically when creating a new criterion" do
      stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 123")
        .to_return(status: 200, body: { "Resources" => [{ "id" => 13 }] }.to_json)

      criterion = context.criteria.create!(groups: { Departments: [{ id: 123 }] })

      criterion.refresh_users!

      expect(criterion.users.size).to eq 1
      expect(criterion.users.first.user_id).to eq "13"
    end

    it "sets the refresh time" do
      criterion = context.criteria.new

      expect(criterion.refreshed_at).to be_nil

      criterion.refresh_users!

      expect(criterion.refreshed_at).to be_a Time
    end
  end

  def external_user(**data)
    Audiences::ExternalUser.new(user_id: data[:id], data: data)
  end
end
