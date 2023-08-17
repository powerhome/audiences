# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:parsed_body) { JSON.parse(last_response.body) }
  let(:example_owner) { ExampleOwner.create!(name: "Example Owner") }

  context "GET /audiences/:context_key" do
    it "responds with the audience context json" do
      get audience_context_path(example_owner)

      expect(parsed_body).to match({ "match_all" => false, "criteria" => [] })
    end

    it "responds with a valid context context_key" do
      get audience_context_path(example_owner), format: :json

      audience = Audiences.load(parsed_body["key"])

      expect(audience.owner).to eql example_owner
    end
  end
end
