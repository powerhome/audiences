# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences do
  describe ".update" do
    let(:baseball_club) { ExampleOwner.create(name: "Baseball Club") }
    let(:token) { Audiences::Context.for(baseball_club).signed_key }

    it "updates an audience context from a given key and params" do
      updated_context = Audiences.update(token, match_all: true)

      expect(updated_context).to be_match_all
    end

    it "updates extra users fetching latest information" do
      user1, user2 = create_users(2)

      updated_context = Audiences.update(token, extra_users: [{ "id" => user1.scim_id }, { "id" => user2.scim_id }])
      expect(updated_context.extra_users).to match_array([user1, user2])
    end

    it "updates group criterion" do
      department1 = create_group(resource_type: "Departments")
      department2 = create_group(resource_type: "Departments")
      territory1 = create_group(resource_type: "Territories")
      territory2 = create_group(resource_type: "Territories")
      title1 = create_group(resource_type: "Titles")
      title2 = create_group(resource_type: "Titles")

      updated_context = Audiences.update(
        token,
        criteria: [
          { "groups" => { "Departments" => [{ "id" => department1.scim_id }, { "id" => department2.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2]

      updated_context = Audiences.update(
        token,
        criteria: [
          { "groups" => { "Departments" => [{ "id" => department1.scim_id }, { "id" => department2.scim_id }],
                          "Territories" => [{ "id" => territory1.scim_id }, { "id" => territory2.scim_id }] } },
          { "groups" => { "Titles" => [{ "id" => title1.scim_id }, { "id" => title2.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2, territory1, territory2]
      expect(updated_context.criteria.last.groups).to match_array [title1, title2]
    end
  end
end
