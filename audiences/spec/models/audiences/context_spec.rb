# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  let(:owner) { ExampleOwner.new(name: "Example") }

  describe "#save" do
    it "publishes a notification about the context update" do
      expect do |blk|
        Audiences::Notifications.subscribe ExampleOwner, &blk
        owner.save!
      end.to yield_with_args(owner.members_context)
    end
  end

  describe "#match_all" do
    it "clears other criteria when set to match all" do
      owner.members_context.criteria.build(groups: { Departments: [1, 3, 4] })
      owner.members_context.match_all = true

      owner.save!

      expect(owner.members_context.criteria).to be_empty
    end

    it "clears extra users when set to match all" do
      owner.members_context.extra_users = [{ "id" => 123 }]
      owner.members_context.match_all = true

      owner.save!

      expect(owner.members_context.extra_users).to be_empty
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:owner) }
  end

  describe "#count" do
    it "is the total of all member users" do
      owner.save!

      owner.members_context.users.create([
                                           { user_id: 1 },
                                           { user_id: 2 },
                                         ])

      expect(owner.members_context.count).to eql 2
    end
  end
end
