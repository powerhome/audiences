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

    it "resolves all users through the configured source when match_all is true" do
      projected_users = create_users(2)
      context = create_context(match_all: true)
      source_users = create_users(2)

      source = instance_double(Audiences::Sources::Legacy)
      allow(Audiences).to receive(:source).and_return(source)
      allow(source).to receive(:all_users).and_return(Audiences::ExternalUser.where(id: source_users))

      expect(context.users).to match_array source_users
      expect(context.users).not_to include(*projected_users)
    end

    it "matches users from any of its criteria, ignoring criteria with no groups" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      context = create_context
      create_criterion(context: context, groups: [department1, title1])
      create_criterion(context: context, groups: [department1, title2])
      create_criterion(context: context, groups: [])

      expect(context.users).to match_array [user1, user3]
    end

    it "resolves criteria matches through the configured source" do
      group = create_group
      projected_users = create_users(2, groups: [group])
      context = create_context
      criterion = create_criterion(context: context, groups: [group])
      source_users = create_users(2)

      source = instance_double(Audiences::Sources::Legacy)
      allow(Audiences).to receive(:source).and_return(source)
      allow(source).to receive(:groups_of).with(criterion).and_return(criterion.groups)
      allow(source).to receive(:users_matching)
        .with(groups: criterion.groups)
        .and_return(Audiences::ExternalUser.where(id: source_users))
      allow(source).to receive(:extra_users_of)
        .with(context)
        .and_return(Audiences::ExternalUser.where(id: []))

      expect(context.users).to match_array source_users
      expect(context.users).not_to include(*projected_users)
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

  describe "saving extra-user selections with configured users" do
    let(:source_user) { ExampleSourceUser.create!(display_name: "Extra") }
    let(:legacy_user) { create_user(scim_id: source_user.id) }
    let(:context) { create_context }
    let(:resolver) { Audiences::SelectionResolver.new }

    before do
      allow(Audiences).to receive(:source).and_return(Audiences::Test::ExampleSource.new)
    end

    it "saves both the legacy and configured reference for a picked extra user" do
      legacy_user
      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))

      selection = context.reload.context_extra_users.sole
      expect(selection.external_user).to eq(legacy_user)
      expect(selection.configured_user).to eq(source_user)
    end

    it "rejects a missing configured user instead of saving only the picks that resolve" do
      legacy_user
      create_user(scim_id: "missing")

      expect do
        context.update!(extra_user_selections: resolver.extra_users(
          references: [{ "id" => source_user.id }, { "id" => "missing" }]
        ))
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rejects a picked configured user without a legacy counterpart" do
      expect do
        context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "replaces the previous extra-user selection" do
      legacy_user
      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))
      replacement = ExampleSourceUser.create!(display_name: "Replacement")
      legacy_replacement = create_user(scim_id: replacement.id)

      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => replacement.id }]))

      expect(context.reload.extra_users).to eq([legacy_replacement])
      expect(context.context_extra_users.sole.configured_user).to eq(replacement)
      expect(Audiences::ContextExtraUser.where(external_user: legacy_user)).to be_empty
    end

    it "removes extra-user selections when given an empty list" do
      legacy_user
      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))

      context.update!(extra_user_selections: [])

      expect(context.reload.context_extra_users).to be_empty
    end

    it "keeps the existing join row for a retained extra user while adding and removing others" do
      legacy_user
      removed = create_user
      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))
      retained = context.context_extra_users.find_by!(external_user: legacy_user)
      context.context_extra_users.create!(external_user: removed)
      added = ExampleSourceUser.create!(display_name: "Added")
      legacy_added = create_user(scim_id: added.id)
      picks = [{ "id" => source_user.id }, { "id" => added.id }]

      context.update!(extra_user_selections: resolver.extra_users(references: picks))

      expect(context.reload.extra_users).to match_array([legacy_user, legacy_added])
      expect(context.context_extra_users.find_by!(external_user: legacy_user).id).to eq(retained.id)
      expect(Audiences::ContextExtraUser.where(context: context, external_user: removed)).to be_empty
      expect(Audiences::ExternalUser.exists?(removed.id)).to be(true)
    end

    it "does not write selection rows when the saved selections have not changed" do
      legacy_user
      picks = [{ "id" => source_user.id }]
      context.update!(extra_user_selections: resolver.extra_users(references: picks))
      selections = resolver.extra_users(references: picks)
      writes = []
      subscriber = ->(_name, _start, _finish, _id, payload) do
        sql = payload[:sql]
        writes << sql if sql.match?(/\A\s*(INSERT|UPDATE|DELETE)\b/i) && sql.include?("audiences_context_extra_users")
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        context.update!(extra_user_selections: selections)
      end

      expect(writes).to be_empty
    end

    it "fills a missing configured reference without replacing the historical join row" do
      selection = context.context_extra_users.create!(external_user: legacy_user)

      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))

      expect(context.reload.context_extra_users.sole.id).to eq(selection.id)
      expect(selection.reload.configured_user).to eq(source_user)
    end

    it "updates a changed configured reference without replacing the retained join row" do
      previous = ExampleSourceUser.create!(display_name: "Previous")
      selection = context.context_extra_users.create!(external_user: legacy_user, configured_user: previous)

      context.update!(extra_user_selections: resolver.extra_users(references: [{ "id" => source_user.id }]))

      expect(context.reload.context_extra_users.sole.id).to eq(selection.id)
      expect(selection.reload.configured_user).to eq(source_user)
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
      allow(Audiences).to receive(:default_users_scope).and_return(-> { where(active: true) })

      active_user = create_user(active: true)
      inactive_user = create_user(active: false)

      context = create_context(extra_users: [active_user, inactive_user])

      expect(context.as_json["extra_users"]).to eql([active_user.as_json])
    end

    context "with selected users in both sources" do
      let(:source_user) { ExampleSourceUser.create!(display_name: "Current user") }
      let(:legacy_user) do
        create_user(
          scim_id: source_user.id.to_s, user_id: source_user.id.to_s, display_name: "Current user",
          data: {
            "id" => source_user.id.to_s,
            "externalId" => source_user.id.to_s,
            "displayName" => "Current user",
          }
        )
      end
      let(:context) do
        create_context(extra_users: [legacy_user]).tap do |context|
          context.context_extra_users.sole.update!(configured_user: source_user)
        end
      end
      let(:expected_json) do
        {
          "match_all" => false,
          "count" => 1,
          "extra_users" => [{
            "id" => source_user.id.to_s,
            "externalId" => source_user.id.to_s,
            "displayName" => "Current user",
          }],
          "criteria" => [],
        }
      end

      before do
        allow(Audiences).to receive(:exposed_user_attributes).and_return(%w[id externalId displayName])
      end

      it "preserves the context response when both sources contain equivalent data" do
        expect(context.as_json).to eq(expected_json)

        Audiences.config.source.use_configured = true

        expect(context.as_json).to eq(expected_json)
      end

      it "renders configured extra-user details rather than stale projection details" do
        legacy_user.update!(data: legacy_user.data.merge("displayName" => "Old user name"))
        Audiences.config.source.use_configured = true

        expect(context.as_json).to eq(expected_json)
      end

      it "applies the default user scope to the configured records being rendered" do
        hidden = ExampleSourceUser.create!(display_name: "Excluded")
        context.context_extra_users.create!(
          external_user: create_user(display_name: "Not yet excluded in projection"), configured_user: hidden
        )
        allow(Audiences).to receive(:default_users_scope).and_return(-> { where.not(display_name: "Excluded") })
        Audiences.config.source.use_configured = true

        expect(context.as_json).to eq(expected_json)
      end
    end
  end
end
