# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context::Locating do
  let(:owner) { ExampleOwner.create(name: "Example") }

  describe ".sign" do
    it "creates a signed token to a given context" do
      cricket_club = ExampleOwner.create(name: "Cricket Club")
      context = Audiences::Context.for(cricket_club)

      loaded_context = Audiences::Context.load(context.signed_key)

      expect(loaded_context.owner).to eql cricket_club
    end
  end

  describe ".for(owner)" do
    it "fetches an existing context" do
      expect(Audiences::Context.for(owner, relation: :members)).to eql owner.members_context
    end

    it "creates a new context when one doesn't exist" do
      expect(Audiences::Context.for(owner)).to be_a Audiences::Context
      expect(Audiences::Context.for(owner)).to be_persisted
    end
  end
end
