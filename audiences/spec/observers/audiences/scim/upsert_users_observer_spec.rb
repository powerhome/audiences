# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::UpsertUsersObserver do
  before(:all) { Audiences::Scim::UpsertUsersObserver.start }
  after(:all) { Audiences::Scim::UpsertUsersObserver.stop }

  describe "#process" do
    describe "creating users" do
      it "creates an external user" do
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => true,
          "photos" => [
            { "value" => "http://example.com/photo/1" },
            { "value" => "http://example.com/photo/2" },
          ],
        }

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last

        expect(created_user.scim_id).to eql "internal-id-123"
        expect(created_user.user_id).to eql "external-id-123"
        expect(created_user.display_name).to eql "My User"
        expect(created_user.picture_url).to eql "http://example.com/photo/1"
        expect(created_user.data).to eql params
        expect(created_user.active).to eql true
      end

      it "creates user with group memberships" do
        new_groups = [
          create_group(scim_id: "group-123"),
          create_group(scim_id: "group-456"),
          create_group(scim_id: "group-789"),
        ]
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "groups" => [
            { "value" => "group-123" },
            { "value" => "group-456" },
            { "value" => "group-789" },
          ],
        }

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to(change { Audiences::ExternalUser.count })

        user = Audiences::ExternalUser.last

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
        expect(user.groups).to match_array new_groups
        expect(user.data).to eql params
      end
    end

    describe "updating users" do
      it "updates an existing external user on a CreateEvent" do
        user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {},
                                              active: true)
        params = { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123",
                   "active" => false }

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
        expect(user.data).to eql params
        expect(user.active).to eql false
      end

      it "updates an existing external user on an ReplaceEvent" do
        user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {})
        params = { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123" }

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
        expect(user.data).to eql params
      end
    end
  end

  context "when required_group_types is configured" do
    before(:all) do
      @old_required_group_types = Audiences.config.required_group_types
      Audiences.config.required_group_types = %w[Departments Titles Territories Roles]
    end

    after(:all) do
      Audiences.config.required_group_types = @old_required_group_types
    end

    before(:each) do
      create_group(scim_id: "group-1", resource_type: "Departments")
      create_group(scim_id: "group-2", resource_type: "Titles")
      create_group(scim_id: "group-3", resource_type: "Territories")
      create_group(scim_id: "group-4", resource_type: "Roles")
    end

    let(:all_required_groups_param) do
      [{ "value" => "group-1" }, { "value" => "group-2" },
       { "value" => "group-3" }, { "value" => "group-4" }]
    end

    let(:all_required_groups) do
      Audiences::Group.where(scim_id: %w[group-1 group-2 group-3 group-4])
    end

    def build_user_params(overrides = {})
      {
        "id" => "internal-id-123",
        "displayName" => "My User",
        "externalId" => "external-id-123",
        "active" => true,
        "groups" => all_required_groups_param,
      }.merge(overrides)
    end

    describe "creating users via events" do
      it "creates user with valid groups via CreateEvent" do
        params = build_user_params

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.scim_id).to eql "internal-id-123"
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "creates user with valid groups via ReplaceEvent" do
        params = build_user_params

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "propagates validation error when groups are invalid" do
        params = build_user_params("groups" => [])

        expect(Audiences::PersistedResourceEvent).not_to receive(:create)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "updating users via events" do
      it "updates user with valid groups via CreateEvent" do
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Old Name", data: {}, active: false)
        params = build_user_params("displayName" => "New Name")

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.display_name).to eql "New Name"
        expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "updates user with valid groups via ReplaceEvent" do
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Old Name", data: {}, active: false)
        params = build_user_params("displayName" => "New Name")

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.display_name).to eql "New Name"
        expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "propagates validation error when update has invalid groups" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                        display_name: "Old Name", data: {}, active: true,
                                        groups: all_required_groups)
        params = build_user_params("groups" => [{ "value" => "group-1" }])

        expect(Audiences::PersistedResourceEvent).not_to receive(:create)

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "inactive users" do
      it "creates inactive user without groups and publishes PersistedResourceEvent" do
        params = build_user_params("active" => false, "groups" => [])

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.active).to be false
        expect(created_user.groups).to be_empty
      end

      it "updates inactive user without groups and publishes PersistedResourceEvent" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                        display_name: "Test", data: {}, active: true,
                                        groups: all_required_groups)
        params = build_user_params("active" => false, "groups" => [])

        expect(Audiences::PersistedResourceEvent).to receive(:create).with(resource_type: "Users", params: params)

        TwoPercent::ReplaceEvent.create(resource: "Users", params: params)

        user = Audiences::ExternalUser.last
        expect(user.active).to be false
        expect(user.groups).to be_empty
      end
    end

    describe "group lookup behavior" do
      it "ignores non-existent group scim_ids in params" do
        params = build_user_params(
          "groups" => all_required_groups_param + [{ "value" => "non-existent-group" }]
        )

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end
    end
  end

  describe "retry behavior" do
    let(:params) do
      { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123", "active" => true }
    end

    before do
      allow_any_instance_of(described_class).to receive(:sleep)
    end

    it "retries and succeeds after transient RecordInvalid errors" do
      call_count = 0
      allow_any_instance_of(Audiences::ExternalUser).to receive(:update!).and_wrap_original do |method, *args|
        call_count += 1
        raise ActiveRecord::RecordInvalid, Audiences::ExternalUser.new if call_count < 2

        method.call(*args)
      end

      expect(Audiences::PersistedResourceEvent).to receive(:create)

      expect do
        TwoPercent::CreateEvent.create(resource: "Users", params: params)
      end.to change { Audiences::ExternalUser.count }.by(1)

      expect(call_count).to eq(2)
    end

    it "raises after exhausting max retries" do
      allow_any_instance_of(Audiences::ExternalUser).to receive(:update!)
        .and_raise(ActiveRecord::RecordInvalid, Audiences::ExternalUser.new)

      expect(Audiences::PersistedResourceEvent).not_to receive(:create)

      expect do
        TwoPercent::CreateEvent.create(resource: "Users", params: params)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "logs a warning on each retry attempt" do
      call_count = 0
      allow_any_instance_of(Audiences::ExternalUser).to receive(:update!).and_wrap_original do |method, *args|
        call_count += 1
        raise ActiveRecord::RecordInvalid, Audiences::ExternalUser.new if call_count < 3

        method.call(*args)
      end

      expect(Audiences.logger).to receive(:warn).with(%r{Retrying \(attempt 2/3\)}).ordered
      expect(Audiences.logger).to receive(:warn).with(%r{Retrying \(attempt 3/3\)}).ordered

      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end
  end
end
