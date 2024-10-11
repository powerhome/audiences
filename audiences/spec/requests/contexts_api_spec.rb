# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences" do
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }

  describe "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audience_context_path(example_owner, :members)

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 0,
                                              "extra_users" => nil,
                                              "criteria" => [],
                                            })
    end
  end

  describe "PUT /audiences/:context_key" do
    let(:users_response) do
      {
        Resources: [{ externalId: 1 }, { externalId: 2 }],
      }
    end

    it "updates the audience context to match all" do
      stub_request(:get, "http://example.com/scim/v2/Users?attributes=id,externalId,displayName,active,photos.type,photos.value&filter=active%20eq%20true")
        .to_return(status: 200, body: users_response.to_json, headers: {})

      put audience_context_path(example_owner, :members), as: :json, params: { match_all: true }

      context = example_owner.members_context.reload

      expect(context).to be_match_all
      expect(context.users.count).to eql 2
    end

    it "updates the context extra users" do
      stub_request(:get, "http://example.com/scim/v2/Users")
        .with(query: {
                attributes: "id,externalId,displayName,active,photos.type,photos.value",
                filter: "(active eq true) and (externalId eq 123)",
              })
        .to_return(status: 200, body: { "Resources" => [{ "displayName" => "John Doe", "externalId" => 123 }] }.to_json)

      put audience_context_path(example_owner, :members),
          as: :json,
          params: { extra_users: [{ externalId: 123, displayName: "John Doe",
                                    photos: [{ value: "http://example.com" }] }] }

      context = example_owner.members_context.reload

      expect(context.extra_users).to eql [{
        "externalId" => 123,
        "displayName" => "John Doe",
      }]
      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 1,
                                              "extra_users" => [{
                                                "externalId" => 123,
                                                "displayName" => "John Doe",
                                              }],
                                              "criteria" => [],
                                            })
    end

    context "updating a group criteria" do
      let(:users_response) do
        {
          Resources: [{ externalId: 1 }, { externalId: 2 }],
        }
      end

      it "allows updating the group criteria" do
        attrs = "id,externalId,displayName,active,photos.type,photos.value"
        stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                           "&filter=(active eq true) and (groups.value eq 123)")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                           "&filter=(active eq true) and (groups.value eq 321)")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                           "&filter=(active eq true) and (groups.value eq 789)")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?attributes=#{attrs}" \
                           "&filter=(active eq true) and (groups.value eq 987)")
          .to_return(status: 200, body: users_response.to_json, headers: {})

        put audience_context_path(example_owner, :members),
            as: :json,
            params: {
              match_all: false,
              criteria: [
                { groups: { Departments: [{ id: 123, displayName: "Finance" }],
                            Territories: [{ id: 321, displayName: "Philadelphia" }] } },
                { groups: { Departments: [{ id: 789, displayName: "Sales" }],
                            Territories: [{ id: 987, displayName: "Detroit" }] } },
              ],
            }

        expect(response.parsed_body).to match({
                                                "match_all" => false,
                                                "extra_users" => [],
                                                "count" => 2,
                                                "criteria" => [
                                                  {
                                                    "id" => anything,
                                                    "count" => 2,
                                                    "groups" => {
                                                      "Departments" => [{ "id" => 123, "displayName" => "Finance" }],
                                                      "Territories" => [{ "id" => 321,
                                                                          "displayName" => "Philadelphia" }],
                                                    },
                                                  },
                                                  {
                                                    "id" => anything,
                                                    "count" => 2,
                                                    "groups" => {
                                                      "Departments" => [{ "id" => 789, "displayName" => "Sales" }],
                                                      "Territories" => [{ "id" => 987, "displayName" => "Detroit" }],
                                                    },
                                                  },
                                                ],
                                              })
      end
    end
  end

  describe "GET /audiences/:context_key/users" do
    it "is the list of users from an audience context" do
      example_owner.members_context.users.create([
                                                   { user_id: 123, data: { "externalId" => 123 } },
                                                   { user_id: 456, data: { "externalId" => 456 } },
                                                   { user_id: 789, data: { "externalId" => 789 } },
                                                 ])

      get audiences.users_path(example_owner.members_context.signed_key)

      expect(response.parsed_body).to match({
                                              "count" => 3,
                                              "users" => [
                                                { "externalId" => 123 },
                                                { "externalId" => 456 },
                                                { "externalId" => 789 },
                                              ],
                                            })
    end
  end

  describe "GET /audiences/:context_key/users/:criterion_id" do
    it "is the list of users from an audience context's criterion" do
      criterion = example_owner.members_context.criteria.create!
      criterion.users.create!([
                                { user_id: 1,
                                  data: { "externalId" => 1,
                                          "displayName" => "John" } },
                                { user_id: 2,
                                  data: { "externalId" => 2,
                                          "displayName" => "Jose" } },
                                { user_id: 3,
                                  data: { "externalId" => 3,
                                          "displayName" => "Nelson" } },
                              ])

      get audiences.users_path(example_owner.members_context.signed_key, criterion_id: criterion.id)

      expect(response.parsed_body).to match_array({
                                                    "count" => 3,
                                                    "users" => [
                                                      { "externalId" => 1, "displayName" => "John" },
                                                      { "externalId" => 2, "displayName" => "Jose" },
                                                      { "externalId" => 3, "displayName" => "Nelson" },
                                                    ],
                                                  })
    end
  end
end
