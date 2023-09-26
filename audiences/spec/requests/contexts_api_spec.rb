# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }

  context "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audience_context_path(example_owner)

      expect(response.parsed_body).to match({ "match_all" => false, "criteria" => [], "resources" => [] })
    end
  end

  context "PUT /audiences/:context_key" do
    it "updates the audience context" do
      put audience_context_path(example_owner), params: { match_all: true }

      context = Audiences::Context.for(example_owner)

      expect(context).to be_match_all
    end

    it "updates the context resources" do
      resources = { resource_id: 123, resource_type: "User", display: "João Doidão" }

      put audience_context_path(example_owner), params: { resources: [resources] }

      context = Audiences::Context.for(example_owner)
      expect(context.resources.as_json).to match(
        [
          hash_including("resource_id" => 123, "resource_type" => "User", "display" => "João Doidão"),
        ]
      )
    end

    it "responds with the audience context json" do
      put audience_context_path(example_owner), params: { match_all: true }

      expect(response.parsed_body).to match({ "match_all" => true, "criteria" => [], "resources" => [] })
    end
  end
end
