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
  describe "#users" do
    it "is all users in the database when match_all is true" do
      users = create_users(4)

      owner.save
      owner.members_context.update!(match_all: true)

      expect(owner.members_external_users).to match_array users
    end

    it "is the union of extra users and criteria matches when match_all is false" do
      group1 = create_group
      group2 = create_group
      _group3 = create_group
      group_users = create_users(2, groups: [group1, group2])
      extra_users = create_users(2)

      owner.save
      owner.members_context.update!(extra_users: extra_users.map(&:as_json))

      expect(owner.members_external_users).to match_array extra_users

      owner.members_context.criteria.create!(groups: [group2])

      expect(owner.members_external_users).to match_array extra_users + group_users
    end

    it "ignores users not matching the default scope" do
      group1 = create_group
      group2 = create_group
      _group3 = create_group
      active_group_user, = create_user(groups: [group1, group2]), create_user(groups: [group1, group2], active: false)
      active_extra_user = create_user
      inactive_extra_user = create_user(active: false)

      owner.save
      owner.members_context.update!(extra_users: [active_extra_user, inactive_extra_user].map(&:as_json))

      expect(owner.members_external_users).to match_array [active_extra_user]

      owner.members_context.criteria.create!(groups: [group2])

      expect(owner.members_external_users).to match_array [active_extra_user, active_group_user]
    end

    it "is only the extra users when no criteria are set and match_all is false" do
      extra_users = create_users(3)

      owner.save
      owner.members_context.update!(extra_users: extra_users, match_all: false)

      expect(owner.members_external_users).to match_array extra_users
    end
  end

  describe "#match_all" do
    it "clears other criteria when set to match all" do
      context = create_context(extra_users: create_users(2))
      create_criterion(context: context, groups: create_groups(1))

      expect(context.criteria.size).to eql 1

      context.update!(match_all: true)

      expect(context.criteria).to be_empty
    end

    it "clears extra users when set to match all" do
      context = create_context(extra_users: create_users(2))

      expect(context.extra_users.size).to eql 2

      context.update!(match_all: true)

      expect(context.extra_users).to be_empty
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:owner) }
  end

  describe "#count" do
    it "is the total of all member users" do
      owner.save!

      owner.members_context.update(extra_users: create_users(2))

      expect(owner.members_context.count).to eql 2
    end
  end
end
