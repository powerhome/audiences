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
      expect(updated_context.extra_users).to eql([user1.data, user2.data])
    end

    it "updates group criterion" do
      group1, group2, group3, group4, group5, group6, group7, group8 = create_groups(8)

      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: group1.scim_id }, { id: group2.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match_array [group1, group2]

      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: group1.scim_id }, { id: group2.scim_id }],
                      Territories: [{ id: group3.scim_id }, { id: group4.scim_id }] } },
          { groups: { Branches: [{ id: group5.scim_id }, { id: group6.scim_id }],
                      Titles: [{ id: group7.scim_id }, { id: group8.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match_array [group1, group2, group3, group4]
      expect(updated_context.criteria.last.groups).to match_array [group5, group6, group7, group8]
    end
  end
end
