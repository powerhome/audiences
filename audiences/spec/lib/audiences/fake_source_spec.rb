# frozen_string_literal: true

require "rails_helper"

RSpec.describe FakeSource do
  subject(:source) { described_class.new }

  # Audiences stores a source record's id as a copy of the scim_id of a legacy
  # record (source_group_id, source_user_id). Each source record is therefore
  # mirrored by a legacy record whose scim_id is the source record's id.
  def create_source_user(display_name: "Source user")
    ExampleSourceUser.create!(display_name: display_name).tap do |user|
      create_user(scim_id: user.id.to_s)
    end
  end

  def create_source_group(resource_type: "Groups", display_name: "#{resource_type} group", users: [])
    ExampleSourceGroup.create!(display_name: display_name, resource_type: resource_type).tap do |group|
      create_group(scim_id: group.id.to_s, resource_type: resource_type)
      users.each { |user| ExampleSourceMembership.create!(example_source_user: user, example_source_group: group) }
    end
  end

  def contract_shape_of(record, display_name:)
    { "id" => record.id.to_s, "externalId" => record.id.to_s, "displayName" => display_name }
  end

  def legacy_users_of(*source_users)
    Audiences::ExternalUser.where(scim_id: source_users.map { |user| user.id.to_s })
  end

  def legacy_groups_of(*source_groups)
    Audiences::Group.where(scim_id: source_groups.map { |group| group.id.to_s })
  end

  describe "#groups_of" do
    it "is the source groups whose ids the criterion stores" do
      stored = create_source_group, create_source_group
      create_source_group
      criterion = create_criterion(groups: legacy_groups_of(*stored))

      expect(source.groups_of(criterion)).to match_array stored
    end
  end

  describe "#users_matching" do
    it "must be a member of any group within each type" do
      user1, user2, user3, user4 = Array.new(4) { create_source_user }
      title1 = create_source_group(resource_type: "Titles", users: [user1, user2])
      title2 = create_source_group(resource_type: "Titles", users: [user3, user4])
      department1 = create_source_group(resource_type: "Departments", users: [user1])
      create_source_group(resource_type: "Departments", users: [user3])
      department3 = create_source_group(resource_type: "Departments", users: [user4])

      users = source.users_matching(groups: [department1, department3, title1, title2])

      expect(users).to match_array [user1, user4]
    end

    it "is no one for no groups" do
      create_source_user

      expect(source.users_matching(groups: [])).to be_empty
    end
  end

  describe "#all_users" do
    it "is every source user" do
      users = Array.new(2) { create_source_user }

      expect(source.all_users).to match_array users
    end
  end

  describe "#extra_users_of" do
    it "is the source users whose ids the context stores" do
      stored = create_source_user, create_source_user
      create_source_user
      context = create_context(extra_users: legacy_users_of(*stored))

      expect(source.extra_users_of(context)).to match_array stored
    end
  end

  describe "#present" do
    it "shapes the users of a relation as id, externalId and displayName" do
      user = create_source_user(display_name: "Ada")

      expect(source.present(ExampleSourceUser.where(id: user.id)))
        .to eq [contract_shape_of(user, display_name: "Ada")]
    end

    it "keeps only the exposed user attributes of a user" do
      user = create_source_user
      allow(Audiences).to receive(:exposed_user_attributes).and_return(%w[id])

      expect(source.present([user])).to eq [{ "id" => user.id.to_s }]
    end

    it "shapes groups as id, externalId and displayName" do
      group = create_source_group(display_name: "Sales")

      expect(source.present([group])).to eq [contract_shape_of(group, display_name: "Sales")]
    end

    it "does not apply the exposed user attributes to a group" do
      group = create_source_group(display_name: "Sales")
      allow(Audiences).to receive(:exposed_user_attributes).and_return(%w[id])

      expect(source.present([group])).to eq [contract_shape_of(group, display_name: "Sales")]
    end
  end

  describe "#identity_keys" do
    it "is the id of each user as a String, in the order of the relation" do
      first, second = Array.new(2) { create_source_user }

      expect(source.identity_keys(ExampleSourceUser.order(id: :desc))).to eq [second.id.to_s, first.id.to_s]
    end
  end

  describe "#search_users" do
    it "narrows the users to those whose display name matches the query" do
      match = create_source_user(display_name: "Alice")
      create_source_user(display_name: "Bob")

      expect(source.search_users(ExampleSourceUser.all, "lic")).to contain_exactly(match)
    end
  end

  describe "#fetch" do
    def fetch(resource_type, query: "", start_index: 0, count: 10)
      source.fetch(resource_type: resource_type, query: query, start_index: start_index, count: count)
    end

    it "lists the users whose display name matches the query, in the client contract" do
      match = create_source_user(display_name: "Alice")
      create_source_user(display_name: "Bob")

      expect(fetch("Users", query: "lic")).to eq [contract_shape_of(match, display_name: "Alice")]
    end

    it "lists only the groups of the resource type" do
      create_source_group(resource_type: "Departments", display_name: "Sales")
      create_source_group(resource_type: "Titles", display_name: "Chief")

      expect(fetch("Departments").pluck("displayName")).to eq ["Sales"]
    end

    it "skips start_index records" do
      3.times { create_source_user }

      expect(fetch("Users", start_index: 2).size).to eq 1
    end

    it "lists at most count records" do
      3.times { create_source_user }

      expect(fetch("Users", count: 2).size).to eq 2
    end

    it "applies the default users scope" do
      create_source_user(display_name: "Alice")
      create_source_user(display_name: "Bob")
      allow(Audiences).to receive(:default_users_scope).and_return(-> { where(display_name: "Alice") })

      expect(fetch("Users").pluck("displayName")).to eq ["Alice"]
    end

    it "applies the default groups scope" do
      create_source_group(resource_type: "Departments", display_name: "Sales")
      create_source_group(resource_type: "Departments", display_name: "Support")
      allow(Audiences).to receive(:default_groups_scope).and_return(-> { where(display_name: "Sales") })

      expect(fetch("Departments").pluck("displayName")).to eq ["Sales"]
    end
  end

  describe "as the configured source" do
    before { allow(Audiences).to receive(:source).and_return(source) }

    let(:extra_user) { create_source_user(display_name: "Extra") }
    let(:member) { create_source_user(display_name: "Member") }
    let(:department) { create_source_group(resource_type: "Departments", display_name: "Sales", users: [member]) }
    let(:context) { create_context(extra_users: legacy_users_of(extra_user)) }
    let!(:criterion) { create_criterion(context: context, groups: legacy_groups_of(department)) }
    let!(:bystander) { create_source_user(display_name: "Bystander") }

    it "calculates Context#users from the source's records" do
      expect(context.users).to match_array [extra_user, member]
    end

    it "counts the users the source calculates" do
      expect(context.count).to eq 2
    end

    it "reads Context#extra_users from the source" do
      expect(context.extra_users).to contain_exactly(extra_user)
    end

    it "renders the extra users of Context#as_json as the source presents them" do
      expect(context.as_json["extra_users"]).to eq [contract_shape_of(extra_user, display_name: "Extra")]
    end

    it "renders Criterion#as_json with the groups the source presents" do
      expect(criterion.as_json).to eq(
        "id" => criterion.id,
        "count" => 1,
        "groups" => { "Departments" => [contract_shape_of(department, display_name: "Sales")] }
      )
    end

    it "finds the identities of the users through the source's identity keys" do
      identity = ExampleUser.create!(id: extra_user.id, name: "Identity")

      expect(context.owner.members).to match_array [identity, nil]
    end

    it "reads no legacy user or group table" do
      expect { context.users.to_a }
        .not_to make_database_queries(matching: /audiences_(external_users|groups|group_memberships)/)
    end

    it "follows the source that is current when it is called" do
      expect(context.users.map(&:class).uniq).to eq [ExampleSourceUser]

      allow(Audiences).to receive(:source).and_return(Audiences::Sources::Legacy.new)

      expect(context.users.map(&:class).uniq).to eq [Audiences::ExternalUser]
    end
  end
end
