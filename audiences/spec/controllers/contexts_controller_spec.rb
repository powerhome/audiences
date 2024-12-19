# frozen_string_literal: true

require "rails_helper"
require_relative "authenticated_endpoint_examples"

RSpec.describe Audiences::ContextsController do
  routes { Audiences::Engine.routes }

  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }
  let(:example_context) { Audiences::Context.for(example_owner, relation: :members) }

  describe "GET /audiences/:context_key" do
    it_behaves_like "authenticated endpoint" do
      subject { get :show, params: { key: example_context.signed_key } }
    end

    it "responds with the audience context json" do
      get :show, params: { key: example_context.signed_key }

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 0,
                                              "extra_users" => nil,
                                              "criteria" => [],
                                            })
    end
  end

  describe "PUT /audiences/:context_key" do
    it_behaves_like "authenticated endpoint" do
      subject { put :update, params: { key: example_context.signed_key } }
    end

    it "updates the audience context to match all" do
      stub_request(:get, "http://example.com/scim/v2/Users")
        .with(query: {
                attributes: "id,externalId,displayName,active,photos.type,photos.value",
                filter: "active eq true",
              })
        .to_return(status: 200, body: { "Resources" => [{ "displayName" => "John Doe", "externalId" => 123 }] }.to_json)

      put :update, params: { key: example_context.signed_key, match_all: true }

      example_context.reload

      expect(example_context).to be_match_all
      expect(example_context.memberships.count).to eq(1)
    end

    it "updates the context extra users" do
      stub_request(:get, "http://example.com/scim/v2/Users")
        .with(query: {
                attributes: "id,externalId,displayName,active,photos.type,photos.value",
                filter: "(active eq true) and (externalId eq 123)",
              })
        .to_return(status: 200, body: { "Resources" => [{ "displayName" => "John Doe", "externalId" => 123 }] }.to_json)

      put :update, params: {
        key: example_context.signed_key,
        extra_users: [{ externalId: 123, displayName: "John Doe", photos: [{ value: "http://example.com" }] }],
      }

      example_context.reload

      expect(example_context.extra_users).to eql [{
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

        put :update, params: {
          key: example_context.signed_key,
          match_all: false,
          criteria: [
            { groups: { Departments: [{ id: 123, displayName: "Finance" }],
                        Territories: [{ id: 321, displayName: "Philadelphia" }] } },
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
                                                      "Departments" => [{ "id" => "123", "displayName" => "Finance" }],
                                                      "Territories" => [{ "id" => "321",
                                                                          "displayName" => "Philadelphia" }],
                                                    },
                                                  },
                                                ],
                                              })
      end
    end
  end

  describe "GET /audiences/:context_key/users" do
    it_behaves_like "authenticated endpoint" do
      subject { get :users, params: { key: example_context.signed_key } }
    end

    it "is the list of users from an audience context" do
      example_owner.members_context.users.create([
                                                   { user_id: 123, data: { "externalId" => 123 } },
                                                   { user_id: 456, data: { "externalId" => 456 } },
                                                   { user_id: 789, data: { "externalId" => 789 } },
                                                 ])

      get :users, params: { key: example_context.signed_key }

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
    let(:criterion) { example_owner.members_context.criteria.create! }

    it_behaves_like "authenticated endpoint" do
      subject { get :users, params: { key: example_context.signed_key, criterion_id: criterion.id } }
    end

    it "is the list of users from an audience context's criterion" do
      criterion.users.create!([
                                { user_id: 1, data: { "externalId" => 1, "displayName" => "John" } },
                                { user_id: 2, data: { "externalId" => 2, "displayName" => "Jose" } },
                                { user_id: 3,
                                  data: { "externalId" => 3, "displayName" => "Nelson", "confidential" => "data" } },
                              ])

      get :users, params: { key: example_context.signed_key, criterion_id: criterion.id }

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
