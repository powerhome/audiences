# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::UsersSearch do
  describe "with ExternalUser (legacy mode)" do
    it "searches through display name in JSON data" do
      john_doe = Audiences::ExternalUser.create(
        user_id: 123,
        data: { displayName: "John Doe" }
      )
      Audiences::ExternalUser.create(
        user_id: 321,
        data: { displayName: "Frank Doe" }
      )

      john_search = Audiences::UsersSearch.new(query: "John")

      expect(john_search.count).to eql 1
      expect(john_search.users.first).to eql john_doe
    end

    it "searches through any field in the JSON data" do
      Audiences::ExternalUser.create(
        user_id: 123,
        data: { displayName: "John Doe" }
      )
      frank_doe = Audiences::ExternalUser.create(
        user_id: 321,
        data: { displayName: "Frank Doe", territory: "Philadelphia" }
      )

      phila_search = Audiences::UsersSearch.new(query: "Phila")

      expect(phila_search.count).to eql 1
      expect(phila_search.users.first).to eql frank_doe
    end
  end

  describe "with ConfiguredUser (configured mode)" do
    it "searches through display_name column" do
      john_doe = create_configured_user(user_id: "123", display_name: "John Doe")
      create_configured_user(user_id: "321", display_name: "Frank Doe")

      john_search = Audiences::UsersSearch.new(scope: ConfiguredUser.all, query: "John")

      expect(john_search.count).to eql 1
      expect(john_search.users.first).to eql john_doe
    end

    it "searches through associated group names" do
      create_configured_user(user_id: "123", display_name: "John Doe")
      frank_doe = create_configured_user(user_id: "321", display_name: "Frank Doe")
      territory = create_configured_group(display_name: "Philadelphia", resource_type: "Territories")

      ConfiguredUserGroup.create!(configured_user: frank_doe, group: territory)

      phila_search = Audiences::UsersSearch.new(scope: ConfiguredUser.all, query: "Phila")

      expect(phila_search.count).to eql 1
      expect(phila_search.users.first).to eql frank_doe
    end

    it "does not return duplicate users when matching multiple groups" do
      user = create_configured_user(user_id: "123", display_name: "John Doe")
      dept = create_configured_group(display_name: "Engineering", resource_type: "Departments")
      title = create_configured_group(display_name: "Engineer", resource_type: "Titles")

      ConfiguredUserGroup.create!(configured_user: user, group: dept)
      ConfiguredUserGroup.create!(configured_user: user, group: title)

      search = Audiences::UsersSearch.new(scope: ConfiguredUser.all, query: "Engin")

      expect(search.count).to eql 1
      expect(search.users).to match_array([user])
    end
  end
end
