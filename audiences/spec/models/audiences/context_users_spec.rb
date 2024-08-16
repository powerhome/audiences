# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ContextUsers do
  context "match_all" do
    it "is the list of all users from SCIM when match_all" do
      response = {
        "Resources" => [
          { "externalId" => 1313 },
          { "externalId" => 1414 },
        ],
      }
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .to_return(status: 200, body: response.to_json)

      context = Audiences::Context.new(match_all: true)
      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 2
      expect(users.first.user_id).to eql "1313"
      expect(users.last.user_id).to eql "1414"
    end
  end

  context "has criteria" do
    it "is the distinct union of users from the criteria" do
      user1 = external_user!("externalId" => 1)
      user2 = external_user!("externalId" => 2)
      user3 = external_user!("externalId" => 3)

      criterion1 = Audiences::Criterion.new(users: [user1, user2])
      criterion2 = Audiences::Criterion.new(users: [user2, user3])
      context = Audiences::Context.new(match_all: false, criteria: [criterion1, criterion2])

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.pluck(:user_id)).to match_array(%w[1 2 3])
    end

    it "includes the extra users uniquely" do
      criterion = Audiences::Criterion.new(users: [external_user!("externalId" => 1),
                                                   external_user!("externalId" => 2)])
      context = Audiences::Context.new(
        match_all: false,
        criteria: [criterion],
        extra_users: [{ "externalId" => 1 }, { "externalId" => 456 }, { "externalId" => 789 }]
      )

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 4
      expect(users[0].user_id).to eql "1"
      expect(users[1].user_id).to eql "456"
      expect(users[2].user_id).to eql "789"
      expect(users[3].user_id).to eql "2"
    end
  end

  def external_user!(**data)
    Audiences::ExternalUser.create(user_id: data["externalId"], data: data)
  end
end
