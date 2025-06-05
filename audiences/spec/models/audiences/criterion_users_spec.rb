# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::CriterionUsers do
  it "is the list of users from the groups criterion" do
    criterion = { Departments: [{ "id" => 1 }, { "id" => 3 }] }
    response = {
      "Resources" => [
        { "externalId" => 1313 },
        { "externalId" => 1414 },
      ],
    }

    attrs = "id,externalId,displayName,active,photos.type,photos.value"
    stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                       "&filter=(active eq true) and (groups.value eq 1 OR groups.value eq 3)")
      .to_return(status: 200, body: response.to_json)

    users = Audiences::CriterionUsers.new(criterion).to_a

    expect(users.size).to eql 2
    expect(users.first.user_id).to eql "1313"
    expect(users.last.user_id).to eql "1414"
  end

  context "when the criteria has different group types" do
    it "is the intersection of users from the groups criterion" do
      criterion = {
        Departments: [{ "id" => 1 }, { "id" => 3 }],
        Territories: [{ "id" => 5 }, { "id" => 6 }],
      }
      response1or3 = {
        "Resources" => [
          { "id" => 1313, "externalId" => 1313 },
          { "id" => 1414, "externalId" => 1414 },
          { "id" => 1515, "externalId" => 1515 },
        ],
      }
      response5or6 = {
        "Resources" => [
          { "id" => 1313, "externalId" => 1313 },
          { "id" => 1515, "externalId" => 1515 },
          { "id" => 1516, "externalId" => 1516 },
        ],
      }

      attrs = "id,externalId,displayName,active,photos.type,photos.value"
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                         "&filter=(active eq true) and (groups.value eq 1 OR groups.value eq 3)")
        .to_return(status: 200, body: response1or3.to_json)
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                         "&filter=(active eq true) and (groups.value eq 5 OR groups.value eq 6)")
        .to_return(status: 200, body: response5or6.to_json)

      users = Audiences::CriterionUsers.new(criterion).to_a

      expect(users.size).to eql 2
      expect(users.first.user_id).to eql "1313"
      expect(users.first.scim_id).to eql "1313"
      expect(users.last.user_id).to eql "1515"
      expect(users.last.scim_id).to eql "1515"
    end

    it "ignores empty types" do
      criterion = {
        Departments: [{ "id" => 1 }, { "id" => 3 }],
        Territories: [],
      }
      response1or3 = {
        "Resources" => [
          { "externalId" => 1313 },
          { "externalId" => 1414 },
          { "externalId" => 1515 },
        ],
      }
      response_no_filter = {
        "Resources" => [
          { "externalId" => 1313 },
          { "externalId" => 1515 },
          { "externalId" => 1516 },
        ],
      }

      attrs = "id,externalId,displayName,active,photos.type,photos.value"
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                         "&filter=(active eq true) and (groups.value eq 1 OR groups.value eq 3)")
        .to_return(status: 200, body: response1or3.to_json)

      stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}&filter=")
        .to_return(status: 200, body: response_no_filter.to_json)

      users = Audiences::CriterionUsers.new(criterion).to_a

      expect(users.size).to eql 3
      expect(users.first.user_id).to eql "1313"
      expect(users.last.user_id).to eql "1515"
    end
  end
end
