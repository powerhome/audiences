# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }
  let(:context_key) { Audiences.sign(example_owner) }

  describe "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audiences.signed_context_path(context_key)

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 0,
                                              "extra_users" => nil,
                                              "criteria" => [],
                                            })
    end
  end

  describe "PUT /audiences/:context_key" do
    it "updates the audience context" do
      put audiences.signed_context_path(context_key), as: :json, params: { match_all: true }

      context = Audiences::Context.for(example_owner)

      expect(context).to be_match_all
    end

    it "updates the context extra users" do
      put audiences.signed_context_path(context_key),
          as: :json,
          params: { extra_users: [{ id: 123, displayName: "John Doe",
                                    photos: [{ value: "http://example.com" }] }] }

      context = Audiences::Context.for(example_owner)
      expect(context.extra_users).to eql [{
        "id" => 123,
        "displayName" => "John Doe",
        "photos" => [{ "value" => "http://example.com" }],
      }]
    end

    it "responds with the audience context json" do
      put audiences.signed_context_path(context_key),
          as: :json,
          params: { extra_users: [{ id: 123, displayName: "John Doe",
                                    photos: [{ value: "http://example.com" }] }] }

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 1,
                                              "extra_users" => [{
                                                "id" => 123,
                                                "displayName" => "John Doe",
                                                "photos" => [{ "value" => "http://example.com" }],
                                              }],
                                              "criteria" => [],
                                            })
    end

    context "updating a group criteria" do
      let(:users_response) do
        {
          Resources: [{ id: 1 }, { id: 2 }],
        }
      end

      it "allows updating the group criteria" do
        stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 123")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 321")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 789")
          .to_return(status: 200, body: users_response.to_json, headers: {})
        stub_request(:get, "http://example.com/scim/v2/Users?filter=groups.value eq 987")
          .to_return(status: 200, body: users_response.to_json, headers: {})

        put audience_context_path(example_owner),
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
                                                "extra_users" => nil,
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
      Audiences::Context.for(example_owner).update!(
        extra_users: [{ "id" => 123 }, { "id" => 456 }, { "id" => 789 }]
      )

      get audiences.users_path(context_key)

      expect(response.parsed_body).to match_array([
                                                    { "id" => 123 },
                                                    { "id" => 456 },
                                                    { "id" => 789 },
                                                  ])
    end
  end

  describe "GET /audiences/:context_key/users/:criterion_id" do
    it "is the list of users from an audience context's criterion" do
      context = Audiences::Context.for(example_owner)
      criterion = context.criteria.create!
      criterion.users.create(user_id: 1, data: { "id" => 1, "displayName" => "John" })
      criterion.users.create(user_id: 2, data: { "id" => 2, "displayName" => "Jose" })
      criterion.users.create(user_id: 3, data: { "id" => 3, "displayName" => "Nelson" })

      get audiences.users_path(context_key, criterion_id: criterion.id)

      expect(response.parsed_body).to match_array([
                                                    { "id" => 1, "displayName" => "John" },
                                                    { "id" => 2, "displayName" => "Jose" },
                                                    { "id" => 3, "displayName" => "Nelson" },
                                                  ])
    end
  end
end
