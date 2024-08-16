# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences do
  describe ".update" do
    let(:baseball_club) { ExampleOwner.create(name: "Baseball Club") }
    let(:token) { Audiences::Context.for(baseball_club).signed_key }

    it "updates an audience context from a given key and params" do
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .with(query: {})
        .to_return(status: 200, body: { "Resources" => [] }.to_json)

      updated_context = Audiences.update(token, match_all: true)

      expect(updated_context).to be_match_all
    end

    it "updates an direct resources collection" do
      updated_context = Audiences.update(token, extra_users: [{ externalId: 678 }])
      expect(updated_context.extra_users).to eql([{ "externalId" => 678 }])

      updated_context = Audiences.update(token, extra_users: [{ externalId: 123 }, { externalId: 321 }])
      expect(updated_context.extra_users).to eql([{ "externalId" => 123 }, { "externalId" => 321 }])
    end

    it "updates group criterion" do
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .with(query: { filter: "groups.value eq 1 OR groups.value eq 2" })
        .to_return(status: 200, body: { "Resources" => [] }.to_json)
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .with(query: { filter: "groups.value eq 3 OR groups.value eq 4" })
        .to_return(status: 200, body: { "Resources" => [] }.to_json)
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .with(query: { filter: "groups.value eq 5 OR groups.value eq 6" })
        .to_return(status: 200, body: { "Resources" => [] }.to_json)
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,photos.type,photos.value")
        .with(query: { filter: "groups.value eq 7 OR groups.value eq 8" })
        .to_return(status: 200, body: { "Resources" => [] }.to_json)

      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: 3 }, { id: 4 }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match({ "Departments" => [{ "id" => 3 }, { "id" => 4 }] })

      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: 1 }, { id: 2 }], Territories: [{ id: 3 }, { id: 4 }] } },
          { groups: { Branches: [{ id: 5 }, { id: 6 }], Titles: [{ id: 7 }, { id: 8 }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match({ "Departments" => [{ "id" => 1 }, { "id" => 2 }],
                                                               "Territories" => [{ "id" => 3 }, { "id" => 4 }] })
      expect(updated_context.criteria.last.groups).to match({ "Branches" => [{ "id" => 5 }, { "id" => 6 }],
                                                              "Titles" => [{ "id" => 7 }, { "id" => 8 }] })
    end
  end
end
