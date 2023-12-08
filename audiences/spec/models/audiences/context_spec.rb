# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  let(:owner) { ExampleOwner.create(name: "Example") }

  describe "#refresh_users!" do
    it "publishes a notification about the context update" do
      context = Audiences::Context.for(owner)

      expect do |blk|
        Audiences::Notifications.subscribe ExampleOwner, &blk
        context.refresh_users!
      end.to yield_with_args
    end
  end

  describe "#match_all" do
    it "clears other criteria when set to match all" do
      context = Audiences::Context.for(owner)
      context.criteria.create(groups: { Departments: [1, 3, 4] })

      context.update(match_all: true)

      expect(context.criteria).to be_empty
    end

    it "clears extra users when set to match all" do
      context = Audiences::Context.for(owner)
      context.update(extra_users: [{ "id" => 123 }])

      context.update(match_all: true)

      expect(context.extra_users).to be_empty
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:owner) }
  end

  describe ".for(owner)" do
    it "fetches an existing context" do
      context = Audiences::Context.create(owner: owner)

      expect(Audiences::Context.for(owner)).to eql context
    end

    it "creates a new context when one doesn't exist" do
      expect(Audiences::Context.for(owner)).to be_a Audiences::Context
    end
  end

  describe "#count" do
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
