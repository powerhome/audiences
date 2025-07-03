# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser, :aggregate_failures do
  describe "associations" do
    it { is_expected.to have_many(:group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:groups).through(:group_memberships).dependent(:destroy) }
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
end
