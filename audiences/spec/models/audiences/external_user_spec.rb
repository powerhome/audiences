# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser, :aggregate_failures do
  describe "associations" do
    it { is_expected.to have_many(:group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:groups).through(:group_memberships).dependent(:destroy) }
  end

  describe "#required_group_types validation" do
    context "when required_group_types is configured" do
      before(:all) do
        @old_required_group_types = Audiences.config.required_group_types
        Audiences.config.required_group_types = %w[Departments Titles Territories Roles]
      end

      after(:all) do
        Audiences.config.required_group_types = @old_required_group_types
      end

      let!(:department_group) { create_group(resource_type: "Departments") }
      let!(:title_group) { create_group(resource_type: "Titles") }
      let!(:territory_group) { create_group(resource_type: "Territories") }
      let!(:role_group) { create_group(resource_type: "Roles") }
      let(:all_required_groups) { [department_group, title_group, territory_group, role_group] }

      describe "active users" do
        it "is valid when user has all required group types" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: all_required_groups
          )

          expect(user).to be_valid
        end

        it "is invalid when user is missing a required group type" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: [title_group, territory_group, role_group]
          )

          expect(user).not_to be_valid
          expect(user.errors[:groups]).to include("must include groups of types: Departments")
        end

        it "is invalid with empty groups" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: []
          )

          expect(user).not_to be_valid
          expect(user.errors[:groups].first).to include("must include groups of types:")
        end

        it "is invalid with no groups" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true
          )

          expect(user).not_to be_valid
        end

        it "validates groups regardless of order" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: [role_group, department_group, title_group, territory_group]
          )

          expect(user).to be_valid
        end

        it "allows user groups to exceed required groups" do
          extra_group = create_group(resource_type: "OtherType")
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: all_required_groups + [extra_group]
          )

          expect(user).to be_valid
        end

        it "allows multiple groups of the same type" do
          extra_department = create_group(resource_type: "Departments")
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: all_required_groups + [extra_department]
          )

          expect(user).to be_valid
        end
      end

      describe "inactive users" do
        it "is valid without any groups" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: false, groups: []
          )

          expect(user).to be_valid
        end

        it "is valid with partial groups" do
          user = Audiences::ExternalUser.new(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: false, groups: [department_group]
          )

          expect(user).to be_valid
        end
      end

      describe "state transitions" do
        it "fails when activating user without required groups" do
          user = Audiences::ExternalUser.create!(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: false, groups: []
          )

          user.active = true
          expect(user).not_to be_valid
        end

        it "succeeds when activating user with all required groups" do
          user = Audiences::ExternalUser.create!(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: false, groups: all_required_groups
          )

          user.active = true
          expect(user).to be_valid
        end

        it "succeeds when deactivating user and removing groups" do
          user = Audiences::ExternalUser.create!(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: all_required_groups
          )

          user.active = false
          user.groups = []
          expect(user).to be_valid
        end

        it "fails when active user removes a required group while staying active" do
          user = Audiences::ExternalUser.create!(
            scim_id: "test-id", user_id: "ext-id", display_name: "Test",
            active: true, groups: all_required_groups
          )

          user.groups = [department_group, title_group, territory_group]
          expect(user).not_to be_valid
        end
      end
    end

    context "when required_group_types is empty" do
      before(:all) do
        @old_required_group_types = Audiences.config.required_group_types
        Audiences.config.required_group_types = []
      end

      after(:all) do
        Audiences.config.required_group_types = @old_required_group_types
      end

      it "allows active user with no groups" do
        user = Audiences::ExternalUser.new(
          scim_id: "test-id", user_id: "ext-id", display_name: "Test",
          active: true, groups: []
        )

        expect(user).to be_valid
      end
    end

    context "when required_group_types is nil" do
      before(:all) do
        @old_required_group_types = Audiences.config.required_group_types
        Audiences.config.required_group_types = nil
      end

      after(:all) do
        Audiences.config.required_group_types = @old_required_group_types
      end

      it "allows active user with no groups" do
        user = Audiences::ExternalUser.new(
          scim_id: "test-id", user_id: "ext-id", display_name: "Test",
          active: true, groups: []
        )

        expect(user).to be_valid
      end
    end
  end

  describe "notifications" do
    it "publishes notifications for relevant contexts based on its gropus when active is changed" do
      group1, _group2 = create_groups(2)
      external_user = create_user(groups: [group1])

      group_relevant_context = create_criterion(groups: [group1]).context
      _irrelevant_context = create_context

      allow(Audiences::Notifications).to receive(:publish)

      external_user.update!(active: false)

      expect(Audiences::Notifications).to(
        have_received(:publish)
          .with(group_relevant_context)
      )
    end

    it "publishes notifications for relevant contexts where the user is an external user when active is changed" do
      group1, _group2 = create_groups(2)
      external_user = create_user(groups: [group1])

      relevant_context = create_context(extra_users: [external_user])
      _irrelevant_context = create_context

      allow(Audiences::Notifications).to receive(:publish)

      external_user.update!(active: false)

      expect(Audiences::Notifications).to(
        have_received(:publish)
          .with(relevant_context)
      )
    end

    it "publishes notifications for relevant match_all contexts when active is changed" do
      group1, _group2 = create_groups(2)
      external_user = create_user(groups: [group1])

      relevant_context = create_context(match_all: true)
      _irrelevant_context = create_context

      allow(Audiences::Notifications).to receive(:publish)

      external_user.update!(active: false)

      expect(Audiences::Notifications).to(
        have_received(:publish)
          .with(relevant_context)
      )
    end

    it "does not publish any notification for relevant contexts when active flag is not changed" do
      group1, _group2 = create_groups(2)
      external_user = create_user(groups: [group1])

      create_criterion(groups: [group1]).context
      create_context(extra_users: [external_user])
      create_context(extra_users: [external_user])

      allow(Audiences::Notifications).to receive(:publish)

      external_user.update!(display_name: false)

      expect(Audiences::Notifications).to_not have_received(:publish)
    end
  end

  describe ".search(query)" do
    it "returns users matching the query" do
      user1 = create_user(display_name: "Alice Smith")
      user2 = create_user(display_name: "Bob Johnson")
      user3 = create_user(display_name: "Charlie Brown")

      results = Audiences::ExternalUser.search("Alice")

      expect(results).to contain_exactly(user1)
      expect(results).not_to include(user2, user3)
    end

    it "performs a case insensitive search" do
      user1 = create_user(display_name: "Alice Smith")
      user2 = create_user(display_name: "Bob Johnson")
      user3 = create_user(display_name: "Charlie Brown")

      results = Audiences::ExternalUser.search("john")

      expect(results).to contain_exactly(user2)
      expect(results).not_to include(user1, user3)
    end
  end

  describe ".matching" do
    it "must be a member of any group within each type" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3, user4])
      department1 = create_group(resource_type: "Departments", external_users: [user1])
      _department2 = create_group(resource_type: "Departments", external_users: [user3])
      department3 = create_group(resource_type: "Departments", external_users: [user4])

      criterion = create_criterion(groups: [department1, department3, title1, title2])

      users = Audiences::ExternalUser.matching(criterion)

      expect(users.pluck(:id)).to match_array [user1.id, user4.id]
    end

    it "ignores empty group types" do
      create_users(4)

      criterion = create_criterion(groups: [])

      users = Audiences::ExternalUser.matching(criterion)

      expect(users).to be_empty
    end
  end

  describe ".matching_any" do
    it "matches all users that match any of the given criterion" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      criterion1 = create_criterion(groups: [department1, title1])
      criterion2 = create_criterion(groups: [department1, title2])

      users = Audiences::ExternalUser.matching_any(criterion1, criterion2)

      expect(users).to match_array [user1, user3]
    end

    it "ignores invalid criterion" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      criterion1 = create_criterion(groups: [department1, title1])
      criterion2 = create_criterion(groups: [])

      users = Audiences::ExternalUser.matching_any(criterion1, criterion2)

      expect(users).to match_array [user1]
    end
  end

  describe "#as_json" do
    it "returns only exposed attributes" do
      user = create_user(
        scim_id: "scim-id",
        user_id: "user-id",
        display_name: "Display Name",
        active: true,
        data: { "displayName" => "value", "hiddenAttribute" => "Does Not Matter" }
      )

      expect(user.as_json).to eq("displayName" => "value",
                                 "groups" => [],
                                 "title" => nil,
                                 "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
                                   "department" => nil,
                                   "role" => nil,
                                   "territory" => nil,
                                   "territoryAbbr" => nil,
                                 })
    end
  end

  describe "#as_scim" do
    it "includes the updated groups from the relational data" do
      user = create_user(
        scim_id: "scim-id",
        user_id: "user-id",
        display_name: "Display Name",
        active: true,
        data: { "displayName" => "Display Name", "groups" => [] }
      )
      title = create_group(resource_type: "Titles", display_name: "Engineer", external_users: [user])
      role = create_group(resource_type: "Roles", display_name: "Admin", external_users: [user])
      department = create_group(resource_type: "Departments", display_name: "Engineering", external_users: [user])
      territory = create_group(resource_type: "Territories", display_name: "Long Island", external_users: [user])

      expect(user.as_scim).to eq(
        "displayName" => "Display Name",
        "groups" => [
          { "value" => title.scim_id, "display" => "Engineer" },
          { "value" => role.scim_id, "display" => "Admin" },
          { "value" => department.scim_id, "display" => "Engineering" },
          { "value" => territory.scim_id, "display" => "Long Island" },
        ],
        "title" => "Engineer",
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
          "role" => "Admin",
          "department" => "Engineering",
          "territory" => "Long Island",
          "territoryAbbr" => "LI",
        }
      )
    end

    it "uses custom territory abbreviations from config" do
      allow(Audiences.config).to receive(:territory_abbreviations).and_return({ "Custom Territory" => "CUST" })

      user = create_user(data: { "displayName" => "Test User" })
      create_group(resource_type: "Territories", display_name: "Custom Territory", external_users: [user])

      scim_data = user.as_scim
      extension_data = scim_data["urn:ietf:params:scim:schemas:extension:authservice:2.0:User"]

      expect(extension_data["territory"]).to eq("Custom Territory")
      expect(extension_data["territoryAbbr"]).to eq("CUST")
    end

    it "returns nil for unknown territories" do
      user = create_user(data: { "displayName" => "Test User" })
      create_group(resource_type: "Territories", display_name: "Unknown Territory", external_users: [user])

      scim_data = user.as_scim
      extension_data = scim_data["urn:ietf:params:scim:schemas:extension:authservice:2.0:User"]

      expect(extension_data["territory"]).to eq("Unknown Territory")
      expect(extension_data["territoryAbbr"]).to be_nil
    end
  end
end
