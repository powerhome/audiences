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

  describe "#count" do
    it "is the total of all users matching any criterion" do
      criterion1 = Audiences::Criterion.new(users: [{ "id" => 1 }, { "id" => 2 }])
      criterion2 = Audiences::Criterion.new(users: [{ "id" => 2 }, { "id" => 3 }])

      context = Audiences::Context.new(criteria: [criterion1, criterion2])

      expect(context.count).to eql 3
    end

    it "also includes the extra users of the context" do
      criterion1 = Audiences::Criterion.new(users: [{ "id" => 1 }, { "id" => 2 }])
      criterion2 = Audiences::Criterion.new(users: [{ "id" => 2 }, { "id" => 3 }])

      context = Audiences::Context.new(criteria: [criterion1, criterion2],
                                       extra_users: [{ "id" => 3 },
                                                     { "id" => 4 }])

      expect(context.count).to eql 4
    end
  end

  describe "#users" do
    it "is the group of all users matching any criterion" do
      criterion1 = Audiences::Criterion.new(users: [{ "id" => 1 }, { "id" => 2 }])
      criterion2 = Audiences::Criterion.new(users: [{ "id" => 2 }, { "id" => 3 }])

      context = Audiences::Context.new(criteria: [criterion1, criterion2])

      expect(context.users).to(
        match_array([{ "id" => 1 }, { "id" => 2 }, { "id" => 3 }])
      )
    end

    it "also includes the extra users of the context" do
      criterion1 = Audiences::Criterion.new(users: [{ "id" => 1 }, { "id" => 2 }])
      criterion2 = Audiences::Criterion.new(users: [{ "id" => 2 }, { "id" => 3 }])

      context = Audiences::Context.new(criteria: [criterion1, criterion2],
                                       extra_users: [{ "id" => 3 },
                                                     { "id" => 4 }])

      expect(context.users).to(
        match_array([{ "id" => 1 }, { "id" => 2 }, { "id" => 3 }, { "id" => 4 }])
      )
    end
  end
end
