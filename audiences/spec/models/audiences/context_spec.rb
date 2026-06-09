# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Context do
  let(:owner) { ExampleOwner.create(name: "Example") }

  # Configure adapter to use ConfiguredUser for testing the new pattern
  before do
    Audiences.config.user_model_class = "ConfiguredUser"
    Audiences.config.use_configured_models = true
  end

  after do
    Audiences.config.user_model_class = nil
    Audiences.config.use_configured_models = false
  end

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

      context.criteria.create!(groups_configured: [group2])

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

  describe "Feature Toggle: extra_users routing" do
    let(:context) { create_context }
    # Create both ExternalUser and ConfiguredUser with matching user_id
    let(:user1) { create_user_with_configured }
    let(:user2) { create_user_with_configured }
    let(:configured1) { ConfiguredUser.find_by(user_id: user1.user_id) }
    let(:configured2) { ConfiguredUser.find_by(user_id: user2.user_id) }

    before do
      # Configure for adapter pattern testing
      Audiences.config.use_configured_models = false
      Audiences.config.dual_write_extra_users = true
      Audiences.config.user_model_class = "ConfiguredUser"
    end

    after do
      # Reset config after tests
      Audiences.config.user_model_class = nil
    end

    describe "association definitions" do
      it "has extra_users_legacy association" do
        expect(context).to respond_to(:extra_users_legacy)
      end

      it "has extra_users_configured association" do
        expect(context).to respond_to(:extra_users_configured)
      end

      it "extra_users_legacy returns ExternalUser records" do
        external_user = Audiences::ExternalUser.create!(user_id: "test-1", display_name: "Test")
        context.context_extra_users.create!(external_user: external_user)

        expect(context.extra_users_legacy.first).to be_a(Audiences::ExternalUser)
        expect(context.extra_users_legacy.first.id).to eq(external_user.id)
      end

      it "extra_users_configured uses the configured model class" do
        skip "external_user_class not configured" unless Audiences.config.external_user_class

        expect(context.extra_users_configured.klass.name).to eq(Audiences.config.external_user_class)
      end
    end

    describe "when use_configured_models is false (legacy mode)" do
      it "routes extra_users to extra_users_legacy association" do
        Audiences.config.use_configured_models = false

        # This will fail until we implement routing method
        expect(context).to respond_to(:extra_users_legacy)
        expect(context).to respond_to(:extra_users_configured)
        expect(context.extra_users).to eq(context.extra_users_legacy)
      end

      it "returns ExternalUser instances from extra_users" do
        Audiences.config.use_configured_models = false
        context.update!(extra_users: [configured1, configured2])

        # When routed to legacy, should return ExternalUser
        expect(context.extra_users.first).to be_a(Audiences::ExternalUser)
      end
    end

    describe "when use_configured_models is true (configured mode)" do
      it "routes extra_users to extra_users_configured association" do
        Audiences.config.use_configured_models = true

        # This will fail until we implement routing method
        expect(context).to respond_to(:extra_users_legacy)
        expect(context).to respond_to(:extra_users_configured)
        expect(context.extra_users).to eq(context.extra_users_configured)
      end

      it "returns configured model instances from extra_users" do
        Audiences.config.use_configured_models = true
        context.update!(extra_users: [configured1, configured2])

        # When routed to configured, should return ConfiguredUser
        expect(context.extra_users.first).to be_a(ConfiguredUser)
      end
    end

    describe "dual-write behavior" do
      it "writes to both associations when dual_write_extra_users is true" do
        Audiences.config.dual_write_extra_users = true
        Audiences.config.use_configured_models = false

        context.update!(extra_users: [configured1, configured2])

        # Both foreign keys should be populated
        expect(context.extra_users_legacy.count).to eq(2)
        expect(context.extra_users_configured.count).to eq(2)
      end

      it "keeps both associations in sync during dual-write" do
        Audiences.config.dual_write_extra_users = true
        context.update!(extra_users: [configured1])

        # Both associations should have matching records
        expect(context.extra_users_legacy.count).to eq(1)
        expect(context.extra_users_configured.count).to eq(1)
        expect(context.extra_users_legacy.first.user_id).to eq(context.extra_users_configured.first.user_id)
      end

      it "only writes to selected association when dual_write is false" do
        Audiences.config.dual_write_extra_users = false
        Audiences.config.use_configured_models = true

        context.update!(extra_users: [configured1])

        # Only configured side should be populated
        expect(context.extra_users_configured.count).to eq(1)
        expect(context.extra_users_legacy.count).to eq(0)
      end
    end

    describe "data consistency" do
      it "maintains consistent counts between associations during dual-write" do
        Audiences.config.dual_write_extra_users = true

        context.update!(extra_users: [configured1, configured2])

        # Both associations should have same count
        expect(context.extra_users_legacy.count).to eq(context.extra_users_configured.count)
      end
    end
  end
end
