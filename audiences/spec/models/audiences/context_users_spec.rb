# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ContextUsers do
  context "match_all" do
    it "is the list of all users from SCIM when match_all" do
      response = {
        "Resources" => [
          { "id" => 1313 },
          { "id" => 1414 },
        ],
      }
      stub_request(:get, "http://example.com/scim/v2/Users")
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
      criterion1 = Audiences::Criterion.new(users: [external_user!("id" => 1), external_user!("id" => 2)])
      criterion2 = Audiences::Criterion.new(users: [external_user!("id" => 2), external_user!("id" => 3)])
      context = Audiences::Context.new(match_all: false, criteria: [criterion1, criterion2])

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 3
      expect(users[0].user_id).to eql "1"
      expect(users[1].user_id).to eql "2"
      expect(users[2].user_id).to eql "3"
    end

    it "includes the extra users" do
      criterion = Audiences::Criterion.new(users: [external_user!("id" => 1), external_user!("id" => 2)])
      context = Audiences::Context.new(
        match_all: false,
        criteria: [criterion],
        extra_users: [{ "id" => 456 }, { "id" => 789 }]
      )

      users = Audiences::ContextUsers.new(context).to_a

      expect(users.size).to eql 4
      expect(users[0].user_id).to eql "1"
      expect(users[1].user_id).to eql "2"
      expect(users[2].user_id).to eql "456"
      expect(users[3].user_id).to eql "789"
    end
  end

  def external_user!(**data)
    Audiences::ExternalUser.for(data)
  end
end