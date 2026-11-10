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

    it "matches all users that match any of the criteria" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      context = create_context
      create_criterion(context: context, groups: [department1, title1])
      create_criterion(context: context, groups: [department1, title2])

      expect(context.users).to match_array [user1, user3]
    end

    it "ignores a criterion left without groups" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      context = create_context
      create_criterion(context: context, groups: [department1, title1])
      emptied = create_criterion(context: context, groups: [create_group])
      Audiences::CriterionGroup.where(criterion_id: emptied.id).delete_all

      expect(Audiences::Context.find(context.id).users).to match_array [user1]
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

  describe "calculation through the source" do
    let(:source) { Audiences::Sources::Legacy.new }
    let(:chosen) { create_user }
    let(:chosen_users) { Audiences::ExternalUser.where(id: chosen.id) }

    before do
      create_users(2)
      allow(Audiences).to receive(:source).and_return(source)
    end

    it "uses the source's users when match_all is true" do
      allow(source).to receive(:all_users).and_return(chosen_users)

      expect(create_context(match_all: true).users).to contain_exactly(chosen)
    end

    it "uses the source's users matching a criterion" do
      criterion = create_criterion(groups: [create_group])
      allow(source).to receive(:users_matching).and_return(chosen_users)

      expect(Audiences::Context.find(criterion.context_id).users).to contain_exactly(chosen)
    end

    it "is no one when there are no criteria and no extra users" do
      allow(source).to receive(:all_users).and_call_original

      expect(create_context.users).to be_empty
      expect(source).to have_received(:all_users)
    end

    it "uses the source's extra users" do
      context = create_context
      allow(source).to receive(:extra_users_of).with(context).and_return(chosen_users)

      expect(context.users).to contain_exactly(chosen)
    end

    it "reads #extra_users from the source" do
      context = create_context
      allow(source).to receive(:extra_users_of).with(context).and_return(chosen_users)

      expect(context.extra_users).to eql chosen_users
    end

    it "renders the extra users through the source" do
      context = create_context(extra_users: [chosen])
      allow(source).to receive(:present).and_return([{ "rendered" => "by the source" }])

      expect(context.as_json["extra_users"]).to eql [{ "rendered" => "by the source" }]
    end

    it "gives the source the extra users matching the default users scope to render" do
      inactive_user = create_user(active: false)
      context = create_context(extra_users: [chosen, inactive_user])
      allow(source).to receive(:present).and_call_original

      context.as_json

      expect(source).to have_received(:present).with(satisfy { |records| records.to_a == [chosen] })
    end
  end

  describe "#extra_users=" do
    it "writes a context_extra_users row for each user" do
      users = create_users(2)
      context = create_context

      context.update!(extra_users: users)

      expect(Audiences::ContextExtraUser.where(context_id: context.id).pluck(:external_user_id))
        .to match_array users.map(&:id)
    end

    it "is read back through #extra_users" do
      users = create_users(2)
      context = create_context

      context.update!(extra_users: users)

      expect(context.extra_users).to match_array users
    end
  end
end
