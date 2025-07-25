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
      context = create_context(match_all: true)

      expect(context.users).to match_array users
    end

    it "is the union of extra users and criteria matches when match_all is false" do
      group1, group2, _group3 = create_groups(3)
      group_users = create_users(2, groups: [group1, group2])
      extra_users = create_users(2)
      context = create_context(extra_users: extra_users)

      expect(context.users).to match_array extra_users

      create_criterion(context: context, groups: [group2])

      expect(context.users).to match_array extra_users + group_users
    end

    it "is only the extra users when no criteria are set and match_all is false" do
      extra_users = create_users(3)
      context = create_context(extra_users: extra_users)

      expect(context.users).to match_array extra_users
    end

    it "ignores users not matching the default scope" do
      group1 = create_group
      group2 = create_group
      _group3 = create_group
      active_group_user, = create_user(groups: [group1, group2]), create_user(groups: [group1, group2], active: false)
      active_extra_user = create_user
      inactive_extra_user = create_user(active: false)

      context = create_context(extra_users: [active_extra_user, inactive_extra_user])

      expect(context.users).to match_array [active_extra_user]

      context.criteria.create!(groups: [group2])

      expect(context.users).to match_array [active_extra_user, active_group_user]
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

  describe "#as_json" do
    it "does not include users not matching the default scope" do
      Audiences.config.default_users_scope = -> { where(active: true) }

      active_user = create_user(active: true)
      inactive_user = create_user(active: false)

      context = create_context(extra_users: [active_user, inactive_user])

      expect(context.as_json["extra_users"]).to eql([active_user.as_json])
    end
  end
end
