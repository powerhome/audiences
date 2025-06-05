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
      user1 = external_user!("id" => 1)
      user2 = external_user!("id" => 2)
      user3 = external_user!("id" => 3)

      criterion1 = Audiences::Criterion.new(users: [user1, user2])
      criterion2 = Audiences::Criterion.new(users: [user2, user3])
      context = Audiences::Context.new(match_all: false, criteria: [criterion1, criterion2])

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.pluck(:user_id)).to match_array(%w[1 2 3])
    end

    it "includes the extra users uniquely" do
      criterion = Audiences::Criterion.new(users: [external_user!("id" => 1),
                                                   external_user!("id" => 2)])
      context = Audiences::Context.new(
        match_all: false,
        criteria: [criterion],
        extra_users: [{ "id" => "1", "externalId" => 1 }, { "id" => "456", "externalId" => 456 },
                      { "id" => "789", "externalId" => 789 }]
      )

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 4
      expect(users[0].scim_id).to eql "1"
      expect(users[1].scim_id).to eql "456"
      expect(users[2].scim_id).to eql "789"
      expect(users[3].scim_id).to eql "2"
    end
  end

  def external_user!(**data)
    Audiences::ExternalUser.create(scim_id: data["id"], user_id: data["id"], data: data)
  end
end
