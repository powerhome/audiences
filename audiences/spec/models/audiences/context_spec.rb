# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  describe "subscriptions" do
    let(:owner) { ExampleOwner.create(name: "Example") }

    it "publishes a notification about the context update" do
      owner = ExampleOwner.create

      expect do |blk|
        Audiences::Notifications.subscribe ExampleOwner, &blk
        Audiences::Context.create(owner: owner)
      end.to yield_with_args
    end
  end

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
      user1 = external_user!(id: 1)
      user2 = external_user!(id: 2)
      user3 = external_user!(id: 3)

      criterion1 = Audiences::Criterion.new(users: [user1, user2])
      criterion2 = Audiences::Criterion.new(users: [user2, user3])

      context = Audiences::Context.new(criteria: [criterion1, criterion2])

      expect(context.count).to eql 3
    end

    it "also includes the extra users of the context" do
      criterion1 = Audiences::Criterion.new(users: [external_user(id: 1), external_user(id: 2)])

      context = Audiences::Context.new(criteria: [criterion1],
                                       extra_users: [{ "id" => 3 },
                                                     { "id" => 4 }])

      expect(context.count).to eql 4
    end
  end

  describe "#users" do
    it "is the group of all users matching any criterion" do
      user1 = external_user!(id: 1)
      user2 = external_user!(id: 2)
      user3 = external_user!(id: 3)

      criterion1 = Audiences::Criterion.new(users: [user1, user2])
      criterion2 = Audiences::Criterion.new(users: [user2, user3])

      context = Audiences::Context.new(criteria: [criterion1, criterion2])

      expect(context.users).to(
        match_array([user1, user2, user3])
      )
    end

    it "also includes the extra users of the context" do
      criterion1 = Audiences::Criterion.new(users: [external_user(id: 1), external_user(id: 2)])

      context = Audiences::Context.new(criteria: [criterion1],
                                       extra_users: [{ "id" => 3 },
                                                     { "id" => 4 }])

      expect(context.users.as_json).to(
        match_array([{ "id" => 3 }, { "id" => 4 }, { "id" => 1 }, { "id" => 2 }])
      )
    end
  end

  def external_user!(...)
    external_user(...).tap(&:save!)
  end

  def external_user(**data)
    Audiences::ExternalUser.new(user_id: data[:id], data: data)
  end
end
