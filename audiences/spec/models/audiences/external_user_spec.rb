# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser, :aggregate_failures do
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
        { "Departments" => [{ "id" => department1.scim_id }], "Titles" => [{ "id" => title2.scim_id }] },
      )

      expect(users.pluck(:display_name)).to match_array [user1.display_name, user3.display_name]
    end
  end

  describe ".wrap" do
    it "takes a list of user data and creates ExternalUser instances, returning them" do
      john, joseph, mary, steve, *others = Audiences::ExternalUser.wrap([
                                                                          { "externalId" => 123,
                                                                            "displayName" => "John Doe" },
                                                                          { "externalId" => 456,
                                                                            "displayName" => "Joseph Doe" },
                                                                          { "externalId" => 789,
                                                                            "displayName" => "Mary Doe" },
                                                                          { "externalId" => 987,
                                                                            "displayName" => "Steve Doe" },
                                                                        ])

      expect(others).to be_empty
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "externalId" => 123, "displayName" => "John Doe" })
      expect(joseph.user_id).to eql "456"
      expect(joseph.data).to match({ "externalId" => 456, "displayName" => "Joseph Doe" })
      expect(mary.user_id).to eql "789"
      expect(mary.data).to match({ "externalId" => 789, "displayName" => "Mary Doe" })
      expect(steve.user_id).to eql "987"
      expect(steve.data).to match({ "externalId" => 987, "displayName" => "Steve Doe" })
    end

    it "updates existing users" do
      joseph = Audiences::ExternalUser.create(user_id: 456, scim_id: 654,
                                              data: { "id" => 654, "externalId" => 456, displayName: "Joseph F. Doe" })
      user_data = [
        { "id" => "321", "externalId" => 123, "displayName" => "John Doe" },
        { "id" => "654", "externalId" => 456, "displayName" => "Joseph Doe" },
      ]

      john, updated_joseph, *others = Audiences::ExternalUser.wrap(user_data).order(:scim_id)

      expect(others).to be_empty
      expect(john.scim_id).to eql "321"
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "id" => "321", "externalId" => 123, "displayName" => "John Doe" })

      expect(updated_joseph).to eql joseph.reload
      expect(updated_joseph.scim_id).to eql "654"
      expect(updated_joseph.user_id).to eql "456"
      expect(updated_joseph.data).to match({ "id" => "654", "externalId" => 456, "displayName" => "Joseph Doe" })
    end
  end
end
