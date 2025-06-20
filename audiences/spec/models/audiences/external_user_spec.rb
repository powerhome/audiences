# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser, :aggregate_failures do
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

      users = Audiences::ExternalUser.matching(
        "Departments" => [{ "id" => department1.scim_id }, { "id" => department3.scim_id }],
        "Titles" => [{ "id" => title1.scim_id }, { "id" => title2.scim_id }]
      )

      expect(users.pluck(:id)).to match_array [user1.id, user4.id]
    end

    it "ignores empty group types" do
      user1, user2, user3, user4 = create_users(4)

      _title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      _title2 = create_group(resource_type: "Titles", external_users: [user3, user4])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user2])
      _department2 = create_group(resource_type: "Departments", external_users: [user3, user4])
      _department3 = create_group(resource_type: "Departments", external_users: [user4])

      users = Audiences::ExternalUser.matching(
        "Departments" => [{ "id" => department1.scim_id }],
        "Titles" => []
      )

      expect(users.pluck(:id)).to match_array [user1.id, user2.id]
    end
  end

  describe ".matching_any" do
    it "matches all users that match any of the given criterion" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3])
      department1 = create_group(resource_type: "Departments", external_users: [user1, user3, user4])

      users = Audiences::ExternalUser.matching_any(
        { "Departments" => [{ "id" => department1.scim_id }], "Titles" => [{ "id" => title1.scim_id }] },
        { "Departments" => [{ "id" => department1.scim_id }], "Titles" => [{ "id" => title2.scim_id }] }
      )

      expect(users.pluck(:display_name)).to match_array [user1.display_name, user3.display_name]
    end
  end
end
