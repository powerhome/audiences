# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Sources::Legacy do
  subject(:source) { described_class.new }

  describe "#groups_of" do
    it "is the criterion's groups" do
      groups = create_groups(2)
      criterion = create_criterion(groups: groups)

      expect(source.groups_of(criterion)).to match_array groups
    end
  end

  describe "#users_matching" do
    it "must be a member of any group within each type" do
      user1, user2, user3, user4 = create_users(4)

      title1 = create_group(resource_type: "Titles", external_users: [user1, user2])
      title2 = create_group(resource_type: "Titles", external_users: [user3, user4])
      department1 = create_group(resource_type: "Departments", external_users: [user1])
      _department2 = create_group(resource_type: "Departments", external_users: [user3])
      department3 = create_group(resource_type: "Departments", external_users: [user4])

      criterion = create_criterion(groups: [department1, department3, title1, title2])

      users = source.users_matching(groups: criterion.groups)

      expect(users.pluck(:id)).to match_array [user1.id, user4.id]
    end

    it "ignores empty group types" do
      create_users(4)

      criterion = create_criterion(groups: [])

      users = source.users_matching(groups: criterion.groups)

      expect(users).to be_empty
    end

    it "does not match every user when the criterion's groups are removed while matching" do
      user1, user2, user3 = create_users(3)
      title = create_group(resource_type: "Titles", external_users: [user1])
      criterion = Audiences::Criterion.find(create_criterion(groups: [title]).id)

      # Simulates a concurrent context update replacing the criteria right after
      # the first read of this criterion's groups.
      removed = false
      remove_groups = ->(*, payload) do
        next if removed || payload[:sql].exclude?("audiences_criterion_groups")

        removed = true
        Audiences::CriterionGroup.where(criterion_id: criterion.id).delete_all
      end

      users = ActiveSupport::Notifications.subscribed(remove_groups, "sql.active_record") do
        source.users_matching(groups: criterion.groups).to_a
      end

      expect(removed).to be true
      expect(users).not_to include(user2, user3)
    end

    it "does not apply the default users scope" do
      inactive_user = create_user(active: false)
      group = create_group(external_users: [inactive_user])

      expect(source.users_matching(groups: [group])).to contain_exactly(inactive_user)
    end
  end

  describe "#all_users" do
    it "is every user, including inactive ones" do
      users = [create_user, create_user(active: false)]

      expect(source.all_users).to match_array users
    end
  end

  describe "#extra_users_of" do
    it "is the context's extra users, including inactive ones" do
      users = [create_user, create_user(active: false)]
      context = create_context(extra_users: users)
      create_context(extra_users: [create_user])

      expect(source.extra_users_of(context)).to match_array users
    end
  end

  describe "#present" do
    it "is the as_json of each record of a relation" do
      users = create_users(2)

      expect(source.present(Audiences::ExternalUser.where(id: users.map(&:id))))
        .to match_array users.map(&:as_json)
    end

    it "is the as_json of each record of an array" do
      group = create_group

      expect(source.present([group])).to eql [group.as_json]
    end
  end

  describe "#search_users" do
    it "narrows the users to those whose data matches the query" do
      john = Audiences::ExternalUser.create(user_id: 123, data: { displayName: "John Doe" })
      Audiences::ExternalUser.create(user_id: 321, data: { displayName: "Frank Doe" })

      expect(source.search_users(Audiences::ExternalUser.all, "John")).to contain_exactly(john)
    end
  end

  describe "#find_users" do
    let!(:user) { create_user(scim_id: "s-1", user_id: "e-1") }

    before { create_user }

    it "finds a user by id" do
      expect(source.find_users([{ "id" => "s-1" }])).to contain_exactly(user)
    end

    it "finds a user by externalId only" do
      expect(source.find_users([{ "externalId" => "e-1" }])).to contain_exactly(user)
    end

    it "finds a user by symbol keys" do
      expect(source.find_users([{ id: "s-1" }])).to contain_exactly(user)
    end

    it "finds no one for an unknown reference" do
      expect(source.find_users([{ "id" => "unknown", "externalId" => "unknown" }])).to be_empty
    end

    it "finds no one for an empty list" do
      expect(source.find_users([])).to be_empty
    end

    it "includes inactive users" do
      inactive = create_user(active: false)

      expect(source.find_users([{ "id" => inactive.scim_id }])).to contain_exactly(inactive)
    end

    it "is an ActiveRecord relation" do
      expect(source.find_users([{ "id" => "s-1" }])).to be_an(ActiveRecord::Relation)
    end
  end

  describe "#identity_keys" do
    it "is one key per user, in the relation's order" do
      first = create_user(user_id: "a")
      second = create_user(user_id: "b")

      users = Audiences::ExternalUser.where(id: [first.id, second.id]).order(id: :desc)

      expect(source.identity_keys(users)).to eql %w[b a]
    end
  end
end
