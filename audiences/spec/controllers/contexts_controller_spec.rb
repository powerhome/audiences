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
        .to_return(status: 200, body: { "Resources" => [{ "displayName" => "John Doe", "externalId" => 123,
                                                          "id" => 321 }] }.to_json)

      put :update, params: { key: example_context.signed_key, match_all: true }

      example_context.reload

      expect(example_context).to be_match_all
      expect(example_context.memberships.count).to eq(1)
    end

    it "updates the context extra users" do
      stub_request(:get, "http://example.com/scim/v2/Users")
        .with(query: {
                attributes: "id,externalId,displayName,active,photos.type,photos.value",
                count: 100,
                filter: "(active eq true) and (externalId eq 123)",
              })
        .to_return(status: 200, body: { "Resources" => [{ "displayName" => "John Doe", "confidential" => "data",
                                                          "externalId" => 123, "id" => 321 }] }.to_json)

      put :update, params: {
        key: example_context.signed_key,
        extra_users: [{ externalId: 123, id: 321, displayName: "John Doe", photos: [{ value: "http://example.com" }] }],
      }

      example_context.reload

      expect(example_context.extra_users).to eql [{
        "id" => 321,
        "externalId" => 123,
        "displayName" => "John Doe",
        "confidential" => "data",
      }]
      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 1,
                                              "extra_users" => [{
                                                "id" => 321,
                                                "externalId" => 123,
                                                "displayName" => "John Doe",
                                              }],
                                              "criteria" => [],
                                            })
    end

    context "updating a group criteria" do
      let(:users_response) do
        {
          Resources: [{ externalId: 1, id: 1 }, { externalId: 2, id: 2 }],
        }
      end

      it "allows updating the group criteria" do
        users = create_users(2)
        department = create_group(resource_type: "Departments", external_users: users)
        territory = create_group(resource_type: "Territories", external_users: users)

        put :update, params: {
          key: example_context.signed_key,
          match_all: false,
          criteria: [
            { groups: { Departments: [{ id: department.scim_id }],
                        Territories: [{ id: territory.scim_id }] } },
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
                                                      "Departments" => [{ "id" => department.scim_id }],
                                                      "Territories" => [{ "id" => territory.scim_id }],
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
                                                   { user_id: 123, scim_id: 123,
                                                     data: { "externalId" => 123, "id" => 123 } },
                                                   { user_id: 456, scim_id: 456,
                                                     data: { "externalId" => 456, "id" => 456 } },
                                                   { user_id: 789, scim_id: 789,
                                                     data: { "externalId" => 789, "id" => 789 } },
                                                 ])

      get :users, params: { key: example_context.signed_key }

      expect(response.parsed_body).to match({
                                              "count" => 3,
                                              "users" => [
                                                { "externalId" => 123, "id" => 123 },
                                                { "externalId" => 456, "id" => 456 },
                                                { "externalId" => 789, "id" => 789 },
                                              ],
                                            })
    end
  end

  describe "GET /audiences/:context_key/users/:criterion_id" do
    it_behaves_like "authenticated endpoint" do
      subject { get :users, params: { key: example_context.signed_key, criterion_id: 123 } }
    end

    it "is the list of users from an audience context's criterion" do
      user = create_user
      group = create_group(external_users: [user])

      criterion = example_context.criteria.create(groups: { "Groups" => [{ "id" => group.scim_id, "externalId" => group.external_id }]})

      get :users, params: { key: example_context.signed_key, criterion_id: criterion.id }

      expect(response.parsed_body).to match_array({
                                                    "count" => 1,
                                                    "users" => [user.data],
                                                  })
    end
  end
end
