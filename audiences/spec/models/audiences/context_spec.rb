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
    let(:owner) { ExampleOwner.create(name: "Example") }

    it "is the total of all member users" do
      user1 = external_user(id: 1)
      user2 = external_user(id: 2)

      context = Audiences::Context.create!(owner: owner, users: [user1, user2])

      expect(context.count).to eql 2
    end
  end

  def external_user(**data)
    Audiences::ExternalUser.new(user_id: data[:id], data: data)
  end
end
