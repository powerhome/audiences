# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  let(:owner) { ExampleOwner.create(name: "Example") }

  describe "context notification" do
    it "publishes a notification about the context updates" do
      expect do |blk|
        Audiences::Notifications.subscribe ExampleOwner, &blk
        owner.members_context.update!(match_all: true)
      end.to yield_with_args(owner.members_context)
    end
  end

  describe "#match_all" do
    it "clears other criteria when set to match all" do
      owner.members_context.criteria.build(groups: { Departments: [1, 3, 4] })
      owner.members_context.match_all = true

      owner.members_context.save!

      expect(owner.members_context.criteria).to be_empty
    end

    it "clears extra users when set to match all" do
      owner.members_context.extra_users = [{ "id" => 123 }]
      owner.members_context.match_all = true

      owner.members_context.save!

      expect(owner.members_context.extra_users).to be_empty
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:owner) }
  end

  describe "#count" do
    it "is the total of all member users" do
      owner.members_context.update(extra_users: create_users(2).map(&:data))

      expect(owner.members_context.count).to eql 2
    end
  end
end
