# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  describe "associations" do
    it { is_expected.to belong_to(:owner) }
  end

  describe ".for(owner)" do
    it "fetches an existing context" do
      owner = ExampleOwner.create(name: "Example")
      context = Audiences::Context.create(owner: owner)

      expect(Audiences::Context.for(owner)).to eql context
    end

    it "creates a new context when one doesn't exist" do
      owner = ExampleOwner.create(name: "Example")

      expect(Audiences::Context.for(owner)).to be_a Audiences::Context
    end
  end
end
