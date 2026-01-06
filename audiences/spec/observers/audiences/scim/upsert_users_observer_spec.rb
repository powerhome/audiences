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

  context "when required_user_group_types is configured" do
    before(:all) do
      @old_required_user_group_types = Audiences.config.required_user_group_types
      Audiences.config.required_user_group_types = %w[Departments Titles Territories Roles]
    end

    after(:all) do
      Audiences.config.required_user_group_types = @old_required_user_group_types
    end

    before(:each) do
      create_group(scim_id: "group-1", resource_type: "Departments")
      create_group(scim_id: "group-2", resource_type: "Titles")
      create_group(scim_id: "group-3", resource_type: "Territories")
      create_group(scim_id: "group-4", resource_type: "Roles")
    end

    describe "with valid groups" do
      describe "creating users" do
        it "creates an external user having all required groups" do
          params = {
            "id" => "internal-id-123",
            "displayName" => "My User",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                         { "value" => "group-4" }],
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to change { Audiences::ExternalUser.count }.by(1)

          created_user = Audiences::ExternalUser.last

          expect(created_user.scim_id).to eql "internal-id-123"
          expect(created_user.user_id).to eql "external-id-123"
          expect(created_user.display_name).to eql "My User"
          expect(created_user.data).to eql params
          expect(created_user.active).to eql true
          expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
        end

        it "creates an external user via ReplaceEvent having all required groups" do
          params = {
            "id" => "internal-id-123",
            "displayName" => "My User",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                         { "value" => "group-4" }],
          }

          expect do
            TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
          end.to change { Audiences::ExternalUser.count }.by(1)

          created_user = Audiences::ExternalUser.last

          expect(created_user.scim_id).to eql "internal-id-123"
          expect(created_user.user_id).to eql "external-id-123"
          expect(created_user.display_name).to eql "My User"
          expect(created_user.data).to eql params
          expect(created_user.active).to eql true
          expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
        end
      end

      describe "updating users" do
        it "updates an existing external user on a CreateEvent having all required groups" do
          user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                                 display_name: "Old Name", data: {}, active: false)
          params = {
            "id" => "internal-id-123",
            "displayName" => "New Name",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                         { "value" => "group-4" }],
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to_not(change { Audiences::ExternalUser.count })

          user.reload

          expect(user.scim_id).to eql "internal-id-123"
          expect(user.user_id).to eql "external-id-123"
          expect(user.display_name).to eql "New Name"
          expect(user.data).to eql params
          expect(user.active).to eql true
          expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
        end

        it "updates an existing external user on a ReplaceEvent having all required groups" do
          user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                                 display_name: "Old Name", data: {}, active: false)
          params = {
            "id" => "internal-id-123",
            "displayName" => "New Name",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                         { "value" => "group-4" }],
          }

          expect do
            TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
          end.to_not(change { Audiences::ExternalUser.count })

          user.reload

          expect(user.scim_id).to eql "internal-id-123"
          expect(user.user_id).to eql "external-id-123"
          expect(user.display_name).to eql "New Name"
          expect(user.data).to eql params
          expect(user.active).to eql true
          expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
        end

        it "allows updating non-group attributes on active user with valid groups" do
          groups = Audiences::Group.where(scim_id: %w[group-1 group-2 group-3 group-4])
          user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                                 display_name: "Original Name", data: {}, active: true,
                                                 groups: groups)
          params = {
            "id" => "internal-id-123",
            "displayName" => "Updated Name",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                         { "value" => "group-4" }],
          }

          expect do
            TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
          end.not_to raise_error

          user.reload
          expect(user.display_name).to eq "Updated Name"
          expect(user.active).to be true
          expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
        end
      end
    end

    describe "with invalid groups" do
      describe "creating users" do
        it "fails to create active user with empty groups array" do
          params = {
            "id" => "internal-id-123",
            "displayName" => "My User",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [],
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "fails to create active user with missing groups key" do
          params = {
            "id" => "internal-id-123",
            "displayName" => "My User",
            "externalId" => "external-id-123",
            "active" => true,
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "fails to create an external user not having all required groups" do
          params = {
            "id" => "internal-id-123",
            "displayName" => "My User",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      describe "updating users" do
        it "fails to update an existing external user on a CreateEvent not having all required groups" do
          Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123",
                                         display_name: "Old Name", data: {}, active: true)
          params = {
            "id" => "internal-id-123",
            "displayName" => "New Name",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
          }

          expect do
            TwoPercent::CreateEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "fails to update an existing external user on a ReplaceEvent not having all required groups" do
          Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123",
                                         display_name: "Old Name", data: {}, active: true)
          params = {
            "id" => "internal-id-123",
            "displayName" => "New Name",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
          }

          expect do
            TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "fails when active user removes a required group while staying active" do
          groups = Audiences::Group.where(scim_id: %w[group-1 group-2 group-3 group-4])
          Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                          display_name: "Active User", data: {}, active: true,
                                          groups: groups)
          params = {
            "id" => "internal-id-123",
            "displayName" => "Still Active",
            "externalId" => "external-id-123",
            "active" => true,
            "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" }],
          }

          expect do
            TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    describe "inactive users" do
      it "creates an inactive user without required groups" do
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => false,
          "groups" => [],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.active).to be false
        expect(created_user.groups).to be_empty
      end

      it "allows removing groups when deactivating user" do
        groups = Audiences::Group.where(scim_id: %w[group-1 group-2 group-3 group-4])
        user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                               display_name: "Active User", data: {}, active: true,
                                               groups: groups)

        params = {
          "id" => "internal-id-123",
          "displayName" => "Now Inactive",
          "externalId" => "external-id-123",
          "active" => false,
          "groups" => [],
        }

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.not_to(change { Audiences::ExternalUser.count })

        user.reload
        expect(user.active).to be false
        expect(user.groups).to be_empty
      end
    end

    describe "activating users" do
      it "fails to activate an inactive user without groups" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                        display_name: "Inactive User", data: {}, active: false)
        params = {
          "id" => "internal-id-123",
          "displayName" => "Now Active",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [],
        }

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "allows activating an inactive user when they have all required groups" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                        display_name: "Inactive User", data: {}, active: false)
        params = {
          "id" => "internal-id-123",
          "displayName" => "Now Active",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                       { "value" => "group-4" }],
        }

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.not_to raise_error

        user = Audiences::ExternalUser.find_by(scim_id: "internal-id-123")
        expect(user.active).to be true
        expect(user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end
    end

    describe "edge cases" do
      it "validates groups regardless of order" do
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [{ "value" => "group-4" }, { "value" => "group-2" }, { "value" => "group-1" },
                       { "value" => "group-3" }],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.active).to be true
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end

      it "allows user groups to exceed required groups" do
        create_group(scim_id: "group-5", resource_type: "Departments")
        create_group(scim_id: "group-6", resource_type: "OtherType")

        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                       { "value" => "group-4" }, { "value" => "group-5" }, { "value" => "group-6" }],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.active).to be true
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4 group-5 group-6])
      end

      it "ignores non-existent group scim_ids" do
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                       { "value" => "group-4" }, { "value" => "non-existent-group" }],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.last
        expect(created_user.groups.pluck(:scim_id)).to match_array(%w[group-1 group-2 group-3 group-4])
      end
    end

    describe "event publishing" do
      it "does not publish PersistedResourceEvent on validation failure" do
        params = {
          "id" => "internal-id-123",
          "displayName" => "My User",
          "externalId" => "external-id-123",
          "active" => true,
          "groups" => [],
        }

        expect(Audiences::PersistedResourceEvent).not_to receive(:create)

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when required_user_group_types is empty" do
      before(:all) do
        @saved_required_types = Audiences.config.required_user_group_types
        Audiences.config.required_user_group_types = []
      end

      after(:all) do
        Audiences.config.required_user_group_types = @saved_required_types
      end

      it "allows creating an active user with no groups" do
        params = {
          "id" => "internal-id-456",
          "displayName" => "No Groups User",
          "externalId" => "external-id-456",
          "active" => true,
          "groups" => [],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.find_by(scim_id: "internal-id-456")
        expect(created_user.active).to be true
        expect(created_user.groups).to be_empty
      end

      it "allows activating an inactive user with no groups" do
        Audiences::ExternalUser.create!(scim_id: "internal-id-456", user_id: "external-id-456",
                                        display_name: "Inactive User", data: {}, active: false)
        params = {
          "id" => "internal-id-456",
          "displayName" => "Now Active",
          "externalId" => "external-id-456",
          "active" => true,
          "groups" => [],
        }

        expect do
          TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
        end.not_to raise_error

        user = Audiences::ExternalUser.find_by(scim_id: "internal-id-456")
        expect(user.active).to be true
        expect(user.groups).to be_empty
      end
    end

    context "when required_user_group_types is nil" do
      before(:all) do
        @saved_required_types = Audiences.config.required_user_group_types
        Audiences.config.required_user_group_types = nil
      end

      after(:all) do
        Audiences.config.required_user_group_types = @saved_required_types
      end

      it "allows creating an active user with no groups" do
        params = {
          "id" => "internal-id-789",
          "displayName" => "No Groups User",
          "externalId" => "external-id-789",
          "active" => true,
          "groups" => [],
        }

        expect do
          TwoPercent::CreateEvent.create(resource: "Users", params: params)
        end.to change { Audiences::ExternalUser.count }.by(1)

        created_user = Audiences::ExternalUser.find_by(scim_id: "internal-id-789")
        expect(created_user.active).to be true
        expect(created_user.groups).to be_empty
      end
    end
  end
end
