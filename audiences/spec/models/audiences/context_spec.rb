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

    context "with a source that returns fresh group relations" do
      let(:source) { FakeSource.new }
      let(:member) { ExampleSourceUser.create!(display_name: "Member") }

      before do
        allow(Audiences).to receive(:source).and_return(source)
        allow(Audiences).to receive(:default_users_scope).and_return(-> { active })
      end

      [1, 5].each do |size|
        it "loads each criterion's groups once when rendering #{size} criteria" do
          extra = ExampleSourceUser.create!(display_name: "Extra")
          context = create_context(extra_users: [create_user(scim_id: extra.id.to_s)])
          types = %w[Departments Titles]
          expected_criteria = Array.new(size) do
            groups = types.map do |type|
              group = ExampleSourceGroup.create!(resource_type: type, display_name: type)
              ExampleSourceMembership.create!(example_source_user: member, example_source_group: group)
              group
            end
            legacy_groups = groups.map { |group| create_group(scim_id: group.id.to_s) }
            criterion = create_criterion(context: context, groups: legacy_groups)
            {
              "id" => criterion.id,
              "count" => 1,
              "groups" => groups.group_by(&:resource_type).transform_values { |of_type| source.present(of_type) },
            }
          end
          context = described_class.find(context.id)
          json = nil

          ActiveRecord::Base.uncached do
            expect { json = context.as_json }
              .to make_database_queries(count: size, matching: /FROM [`"]example_source_groups[`"]/)
          end

          expect(json).to eq(
            "match_all" => false,
            "count" => 2,
            "extra_users" => source.present([extra]),
            "criteria" => expected_criteria
          )
        end
      end

      it "does not retain loaded source groups between renders" do
        group = ExampleSourceGroup.create!(resource_type: "Titles", display_name: "Original")
        criterion = create_criterion(groups: [create_group(scim_id: group.id.to_s)])
        context = criterion.context

        expect(context.as_json.dig("criteria", 0, "groups", "Titles", 0, "displayName")).to eq("Original")

        group.update!(display_name: "Updated")

        expect(context.as_json.dig("criteria", 0, "groups", "Titles", 0, "displayName")).to eq("Updated")
      end

      it "renders a criterion without resolved groups as empty and matching nobody" do
        member
        criterion = create_criterion(groups: [create_group(scim_id: "missing")])
        context = described_class.find(criterion.context_id)

        expect(context.as_json).to include(
          "count" => 0,
          "criteria" => [{ "id" => criterion.id, "count" => 0, "groups" => {} }]
        )
      end
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

  describe "#source_user_ids" do
    it "is the source id of each extra user" do
      users = create_users(2)
      context = create_context(extra_users: users)

      expect(described_class.find(context.id).source_user_ids).to match_array users.map(&:scim_id)
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
