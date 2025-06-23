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
      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: 3 }, { id: 4 }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match({ "Departments" => [{ "id" => 3 }, { "id" => 4 }] })

      updated_context = Audiences.update(
        token,
        criteria: [
          { groups: { Departments: [{ id: 1 }, { id: 2 }], Territories: [{ id: 3 }, { id: 4 }] } },
          { groups: { Branches: [{ id: 5 }, { id: 6 }], Titles: [{ id: 7 }, { id: 8 }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match({ "Departments" => [{ "id" => 1 }, { "id" => 2 }],
                                                               "Territories" => [{ "id" => 3 }, { "id" => 4 }] })
      expect(updated_context.criteria.last.groups).to match({ "Branches" => [{ "id" => 5 }, { "id" => 6 }],
                                                              "Titles" => [{ "id" => 7 }, { "id" => 8 }] })
    end
  end
end
