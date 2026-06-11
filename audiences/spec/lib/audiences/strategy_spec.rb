# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Strategy Pattern" do
  describe Audiences::LegacyStrategy do
    subject(:strategy) { described_class.new }

    describe "#active_users" do
      it "returns ExternalUser.active scope" do
        user1 = create_legacy_user(active: true)
        user2 = create_legacy_user(active: true)
        create_legacy_user(active: false)

        result = strategy.active_users

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#members_of" do
      it "returns users who are members of given groups" do
        user1 = create_legacy_user
        user2 = create_legacy_user
        create_legacy_user
        group = create_legacy_group

        Audiences::GroupMembership.create!(external_user: user1, group: group)
        Audiences::GroupMembership.create!(external_user: user2, group: group)

        result = strategy.members_of([group])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_by_ids" do
      it "finds users by primary key ids" do
        user1 = create_legacy_user
        user2 = create_legacy_user
        create_legacy_user

        result = strategy.find_by_ids([user1.id, user2.id]) # rubocop:disable Rails/DynamicFindBy

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_by_identifiers" do
      it "finds users by id only" do
        user1 = create_legacy_user(user_id: "ext-123")
        user2 = create_legacy_user(user_id: "ext-456")
        create_legacy_user(user_id: "ext-789")

        result = strategy.find_by_identifiers(ids: [user1.id, user2.id], external_ids: [])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by external_id only" do
        user1 = create_legacy_user(user_id: "ext-123")
        user2 = create_legacy_user(user_id: "ext-456")
        create_legacy_user(user_id: "ext-789")

        result = strategy.find_by_identifiers(ids: [], external_ids: %w[ext-123 ext-456])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_groups" do
      it "finds groups using Group.from_scim" do
        group = create_legacy_group(resource_type: "Departments", external_id: "dept-1")

        result = strategy.find_groups("Departments", [{ "id" => group.scim_id }])

        expect(result.map(&:id)).to eq([group.id])
      end
    end

    describe "#get_users_from_context" do
      it "returns extra_users_legacy association" do
        context = create_context
        user = create_legacy_user
        context.context_extra_users.create!(external_user: user)

        result = strategy.get_users_from_context(context)

        expect(result.first.id).to eq(user.id)
      end
    end

    describe "#none" do
      it "returns empty relation" do
        expect(strategy.none).to be_empty
      end
    end
  end

  describe Audiences::ConfiguredStrategy do
    let(:config) { Audiences.config }
    subject(:strategy) { described_class.new(config) }

    before do
      allow(config).to receive(:user_model_class).and_return(ConfiguredUser)
      allow(config).to receive(:group_model_class).and_return(ConfiguredGroup)

      # Set up procs for configured mode
      allow(config).to receive(:active_users_scope_proc).and_return(
        ->(relation) { relation.where(active: true) }
      )
      allow(config).to receive(:members_of_scope_proc).and_return(
        ->(relation, groups) {
          relation.joins(:configured_user_groups).where(configured_user_groups: { group: groups }).distinct
        }
      )
      allow(config).to receive(:find_by_ids_proc).and_return(
        ->(relation, ids) { relation.where(id: ids) }
      )
      allow(config).to receive(:find_groups_proc).and_return(
        ->(_resource_type, group_data) do
          ids = group_data.filter_map { |h| h["id"] }
          ConfiguredGroup.where(id: ids)
        end
      )
    end

    describe "#active_users" do
      it "uses active_users_scope_proc" do
        user1 = create_configured_user(active: true)
        user2 = create_configured_user(active: true)
        create_configured_user(active: false)

        result = strategy.active_users

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#members_of" do
      it "uses members_of_scope_proc" do
        user1 = create_configured_user
        user2 = create_configured_user
        create_configured_user
        group = create_configured_group

        ConfiguredUserGroup.create!(configured_user: user1, group: group)
        ConfiguredUserGroup.create!(configured_user: user2, group: group)

        result = strategy.members_of([group])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_by_ids" do
      it "uses find_by_ids_proc" do
        user1 = create_configured_user
        user2 = create_configured_user
        create_configured_user

        result = strategy.find_by_ids([user1.id, user2.id]) # rubocop:disable Rails/DynamicFindBy

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_by_identifiers" do
      it "finds users by id only" do
        user1 = create_configured_user(user_id: "ext-123")
        user2 = create_configured_user(user_id: "ext-456")
        create_configured_user(user_id: "ext-789")

        result = strategy.find_by_identifiers(ids: [user1.id, user2.id], external_ids: [])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by external_id only" do
        user1 = create_configured_user(user_id: "ext-123")
        user2 = create_configured_user(user_id: "ext-456")
        create_configured_user(user_id: "ext-789")

        result = strategy.find_by_identifiers(ids: [], external_ids: %w[ext-123 ext-456])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end
    end

    describe "#find_groups" do
      it "uses find_groups_proc" do
        group = create_configured_group(resource_type: "Departments", external_id: "dept-1")

        result = strategy.find_groups("Departments", [{ "id" => group.id }])

        expect(result.map(&:id)).to eq([group.id])
      end
    end

    describe "#get_users_from_context" do
      it "returns extra_users_configured association" do
        context = create_context
        user = create_configured_user
        context.context_extra_users.create!(configured_user_id: user.id)

        result = strategy.get_users_from_context(context)

        expect(result.first.id).to eq(user.id)
      end
    end

    describe "#none" do
      it "returns empty relation" do
        expect(strategy.none).to be_empty
      end
    end
  end
end
