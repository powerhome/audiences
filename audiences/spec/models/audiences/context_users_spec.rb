# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ContextUsers do
  context "match_all" do
    it "is the list of all users from SCIM when match_all" do
      response = {
        "Resources" => [
          { "id" => "3131", "externalId" => 1313 },
          { "id" => "4141", "externalId" => 1414 },
        ],
      }
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,active,photos.type,photos.value&filter=active%20eq%20true")
        .to_return(status: 200, body: response.to_json)

      context = Audiences::Context.new(match_all: true)
      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 2
      expect(users.first.user_id).to eql "1313"
      expect(users.first.scim_id).to eql "3131"
      expect(users.last.user_id).to eql "1414"
      expect(users.last.scim_id).to eql "4141"
    end
  end

  context "has criteria" do
    it "is the distinct union of users from the criteria" do
      user1, user2, user3 = create_users(3)

      criterion1 = Audiences::Criterion.new
      allow(criterion1).to receive(:users) { [user1, user2] }
      criterion2 = Audiences::Criterion.new
      allow(criterion2).to receive(:users) { [user2, user3] }
      context = Audiences::Context.new(match_all: false, criteria: [criterion1, criterion2])

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.pluck(:id)).to match_array([user1.id, user2.id, user3.id])
    end

    it "includes the extra users uniquely" do
      criterion_user1, criterion_user2 = create_users(2)
      criterion = Audiences::Criterion.new

      scim_id = next_scim_id
      extra_user = { "id" => scim_id, "externalId" => scim_id, "displayName" => "Extra User" }

      context = Audiences::Context.new(
        match_all: false,
        criteria: [criterion],
        extra_users: [criterion_user1.data, extra_user]
      )
      allow(criterion).to receive(:users) { [criterion_user1, criterion_user2] }

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 3
      expect(users.pluck(:scim_id)).to match_array([
        criterion_user1.scim_id,
        criterion_user2.scim_id,
        extra_user["id"].to_s,
      ])
    end
  end
end
