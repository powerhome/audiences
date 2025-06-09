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
      create_users 5

      put :update, params: { key: example_context.signed_key, match_all: true }

      example_context.reload

      expect(example_context).to be_match_all
      expect(example_context.users.count).to eq(5)
    end

    it "updates the context extra users" do
      user = create_user

      put :update, params: {
        key: example_context.signed_key,
        extra_users: [user.data],
      }

      example_context.reload

      expect(example_context.extra_users).to eql [user.data]
      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "count" => 1,
                                              "extra_users" => [user.data],
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
      users = create_users 3

      example_context.update(extra_users: users.map(&:data))

      get :users, params: { key: example_context.signed_key }

      expect(response.parsed_body).to match({
                                              "count" => 3,
                                              "users" => match_array(users.map(&:data)),
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

      criterion = example_context.criteria.create(groups: { "Groups" => [{ "id" => group.scim_id,
                                                                           "externalId" => group.external_id }] })

      get :users, params: { key: example_context.signed_key, criterion_id: criterion.id }

      expect(response.parsed_body).to match_array({
                                                    "count" => 1,
                                                    "users" => [user.data],
                                                  })
    end
  end
end
