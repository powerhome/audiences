# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Integrations::UpsertUsersObserver do
  before(:all) { Audiences::Integrations::UpsertUsersObserver.start }
  after(:all) { Audiences::Integrations::UpsertUsersObserver.stop }

  describe "#process" do
    describe "creating users" do
      it "creates an external user" do
        user_attributes = {
          scim_id: "internal-id-123",
          display_name: "My User",
          external_id: "external-id-123",
          active: true,
          photos: [
            { "value" => "http://example.com/photo/1" },
            { "value" => "http://example.com/photo/2" },
          ],
        }

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last

        expect(created_user.scim_id).to eql "internal-id-123"
        expect(created_user.user_id).to eql "external-id-123"
        expect(created_user.display_name).to eql "My User"
        expect(created_user.picture_url).to eql "http://example.com/photo/1"
        expect(created_user.active).to eql true
      end

      it "creates user with group memberships" do
        new_groups = [
          create_group(scim_id: "group-123"),
          create_group(scim_id: "group-456"),
          create_group(scim_id: "group-789"),
        ]
        user_attributes = {
          scim_id: "internal-id-123",
          display_name: "My User",
          external_id: "external-id-123",
          active: true,
          groups: [
            { scim_id: "group-123" },
            { scim_id: "group-456" },
            { scim_id: "group-789" },
          ],
        }

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to(change { Audiences::ExternalUser.count })

        user = Audiences::ExternalUser.last

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
        expect(user.groups).to match_array new_groups
      end
    end

    describe "updating users" do
      it "updates an existing external user on a CreateEvent" do
        user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {},
                                              active: true)
        user_attributes = {
          scim_id: "internal-id-123",
          display_name: "My User",
          external_id: "external-id-123",
          active: false
        }

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
        expect(user.active).to eql false
      end

      it "updates an existing external user on an ReplaceEvent" do
        user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {})
        user_attributes = {
          scim_id: "internal-id-123",
          display_name: "My User",
          external_id: "external-id-123",
          active: true
        }

        expect do
          TestDomainEvents::UserUpdated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload

        expect(user.scim_id).to eql "internal-id-123"
        expect(user.user_id).to eql "external-id-123"
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
      [{ scim_id: "group-1" }, { scim_id: "group-2" },
       { scim_id: "group-3" }, { scim_id: "group-4" }]
    end

    let(:all_required_groups) do
      Audiences::Group.where(scim_id: %w[group-1 group-2 group-3 group-4])
    end

    def build_user_attributes(overrides = {})
      {
        scim_id: "internal-id-123",
        display_name: "My User",
        external_id: "external-id-123",
        active: true,
        groups: all_required_groups_param,
      }.merge(overrides)
    end

    describe "creating users via events" do
      it "creates user with valid groups via CreateEvent" do
        user_attributes = build_user_attributes

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.scim_id).to eql "internal-id-123"
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "creates user with valid groups via ReplaceEvent" do
        user_attributes = build_user_attributes

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "creates user but does not publish event when groups are invalid" do
        user_attributes = build_user_attributes(groups: [])

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.scim_id).to eql "internal-id-123"
        expect(created_user.groups).to be_empty
      end
    end

    describe "updating users via events" do
      it "updates user with valid groups via CreateEvent" do
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Old Name", data: {}, active: false)
        user_attributes = build_user_attributes(display_name: "New Name")

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.display_name).to eql "New Name"
        expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "updates user with valid groups via ReplaceEvent" do
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Old Name", data: {}, active: false)
        user_attributes = build_user_attributes(display_name: "New Name")

        expect do
          TestDomainEvents::UserUpdated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.display_name).to eql "New Name"
        expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "updates user but does not publish event when update has invalid groups" do
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Old Name", data: {}, active: true,
                                               groups: all_required_groups)
        user_attributes = build_user_attributes(groups: [{ scim_id: "group-1" }])

        expect do
          TestDomainEvents::UserUpdated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to_not(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.groups.pluck(:scim_id)).to eq(["group-1"])
      end
    end

    describe "inactive users" do
      it "creates inactive user without groups but does not publish PersistedResourceEvent" do
        user_attributes = build_user_attributes(active: false, groups: [])

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.active).to be false
        expect(created_user.groups).to be_empty
      end

      it "updates inactive user without groups but does not publish PersistedResourceEvent" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                        display_name: "Test", data: {}, active: true,
                                        groups: all_required_groups)
        user_attributes = build_user_attributes(active: false, groups: [])

        TestDomainEvents::UserUpdated.create(
          user_attributes: user_attributes,
          correlation_id: "test-correlation-id"
        )

        user = Audiences::ExternalUser.last
        expect(user.active).to be false
        expect(user.groups).to be_empty
      end
    end

    describe "group lookup behavior" do
      it "ignores non-existent group scim_ids in params" do
        user_attributes = build_user_attributes(
          groups: all_required_groups_param + [{ scim_id: "non-existent-group" }]
        )

        expect do
          TestDomainEvents::UserCreated.create(
            user_attributes: user_attributes,
            correlation_id: "test-correlation-id"
          )
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end
    end
  end
end
