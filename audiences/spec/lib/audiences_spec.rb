# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences do
  describe ".sign" do
    it "creates a signed token to a given context" do
      cricket_club = ExampleOwner.create(name: "Cricket Club")

      token = Audiences.sign(cricket_club)
      context = Audiences.load(token)

      expect(context.owner).to eql cricket_club
    end
  end

  describe ".update" do
    let(:baseball_club) { ExampleOwner.create(name: "Baseball Club") }
    let(:token) { Audiences.sign(baseball_club) }

    it "updates an audience context from a given key and params" do
      updated_context = Audiences.update(token, match_all: true)

      expect(updated_context).to be_match_all
    end

    it "updates an direct resources collection" do
      updated_context = Audiences.update(token, resources: [
                                           { resource_id: 123, resource_type: "User", display: "João Doidão" },
                                           { resource_id: 321, resource_type: "User", display: "Nelson" },
                                         ])

      expect(updated_context.resources.as_json).to match(
        [
          hash_including("resource_id" => 123, "resource_type" => "User", "display" => "João Doidão"),
          hash_including("resource_id" => 321, "resource_type" => "User", "display" => "Nelson"),
        ]
      )
    end
  end
end
