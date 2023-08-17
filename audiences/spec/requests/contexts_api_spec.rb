# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }

  context "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audience_context_path(example_owner)

      expect(response.parsed_body).to match({ "match_all" => false, "criteria" => [] })
    end
  end

  context "PUT /audiences/:context_key" do
    it "updates the audience context" do
      put audience_context_path(example_owner), params: { match_all: true }

      context = Audiences::Context.for(example_owner)

      expect(context).to be_match_all
    end

    it "responds with the audience context json" do
      put audience_context_path(example_owner), params: { match_all: true }

      expect(response.parsed_body).to match({ "match_all" => true, "criteria" => [] })
    end
  end
end
