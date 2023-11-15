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
      updated_context = Audiences.update(token, extra_users: [123, 321])

      expect(updated_context.extra_users).to eql([123, 321])
    end

    it "updates group criterion" do
      updated_context = Audiences.update(token, extra_users: [123, 321])

      expect(updated_context.extra_users).to eql([123, 321])
    end
  end
end
