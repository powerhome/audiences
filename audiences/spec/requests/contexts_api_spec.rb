# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }

  context "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audience_context_path(example_owner)

      expect(response.parsed_body).to match({ "match_all" => false, "extra_users" => nil, "criteria" => {} })
    end
  end

  context "PUT /audiences/:context_key" do
    it "updates the audience context" do
      put audience_context_path(example_owner), as: :json, params: { match_all: true }

      context = Audiences::Context.for(example_owner)

      expect(context).to be_match_all
    end

    it "updates the context extra users" do
      put audience_context_path(example_owner),
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
      put audience_context_path(example_owner),
          as: :json,
          params: { extra_users: [{ id: 123, displayName: "John Doe",
                                    photos: [{ value: "http://example.com" }] }] }

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "extra_users" => [{
                                                "id" => 123,
                                                "displayName" => "John Doe",
                                                "photos" => [{ "value" => "http://example.com" }],
                                              }],
                                              "criteria" => {},
                                            })
    end

    it "allows updating the group criteria" do
      put audience_context_path(example_owner),
          as: :json,
          params: {
            match_all: false,
            criteria: {
              groups: [
                { Departments: [{ id: 123, displayName: "Finance" }],
                  Territories: [{ id: 321, displayName: "Philadelphia" }] },
                { Departments: [{ id: 789, displayName: "Sales" }],
                  Territories: [{ id: 987, displayName: "Detroit" }] },
              ],
            },
          }

      expect(response.parsed_body).to match({
                                              "match_all" => false,
                                              "extra_users" => nil,
                                              "criteria" => {
                                                "groups" => [
                                                  { "Departments" => [{ "id" => 123, "displayName" => "Finance" }],
                                                    "Territories" => [{ "id" => 321,
                                                                        "displayName" => "Philadelphia" }] },
                                                  { "Departments" => [{ "id" => 789, "displayName" => "Sales" }],
                                                    "Territories" => [{ "id" => 987, "displayName" => "Detroit" }] },
                                                ],
                                              },
                                            })
    end
  end
end
