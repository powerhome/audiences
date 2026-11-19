# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Model do
  subject { ExampleOwner.new }

  describe "dynamic owner to audience relations" do
    it do
      is_expected.to have_one(:members_context).class_name("Audiences::Context")
    end
  end

  describe "#relation_name" do
    it "is the collection of identity objects from the context users" do
      example_users = Array.new(3) { ExampleUser.create(name: "User #{_1}") }
      external_users = example_users.map { create_user(user_id: _1.id) }
      context = create_context(extra_users: external_users)

      expect(context.owner.members).to match_array example_users
    end
  end

  describe "#relation_name identity lookup" do
    it "asks the source for the identity key of each user" do
      source = Audiences::Sources::Legacy.new
      allow(Audiences).to receive(:source).and_return(source)
      allow(source).to receive(:identity_keys).and_call_original
      user = ExampleUser.create(name: "Identity")
      context = create_context(extra_users: [create_user(user_id: user.id)])

      context.owner.members

      expect(source).to have_received(:identity_keys).with(satisfy { |users| users.to_a == context.users.to_a })
    end

    it "looks up the identities of five users in one query" do
      identities = Array.new(5) { ExampleUser.create(name: "Identity #{_1}") }
      external_users = identities.map { create_user(user_id: _1.id) }
      owner = create_context(extra_users: external_users).owner

      expect { owner.members.to_a }.to make_database_queries(count: 1, matching: "example_users")
    end

    it "has nil for a user without an identity" do
      with_identity = ExampleUser.create(name: "Identity")
      context = create_context(extra_users: [create_user(user_id: with_identity.id), create_user(user_id: "0")])

      expect(context.owner.members).to match_array [with_identity, nil]
    end

    it "does not match a user without a key to an identity whose key is empty" do
      ExampleUser.create(name: nil)
      allow(Audiences.config).to receive(:identity_key).and_return(:name)
      source = Audiences::Sources::Legacy.new
      allow(Audiences).to receive(:source).and_return(source)
      allow(source).to receive(:identity_keys).and_return([nil])
      context = create_context(extra_users: [create_user])

      expect(context.owner.members).to eql [nil]
    end
  end

  describe "#relation_name_external_users" do
    it "is the collection of external users objects from the context users" do
      external_users = create_users(2)
      context = create_context(extra_users: external_users)

      expect(context.owner.members_external_users).to match_array external_users
    end
  end

  describe "dynamic scopes" do
    before { subject.save! }

    it "allows to eager load the context" do
      owner = ExampleOwner.with_members_context.first

      expect(owner.association(:members_context)).to be_loaded
    end
  end

  it "builds the audience context as the owner is built" do
    expect(subject.members_context).to be_present
  end

  it "saves the audience context as the owner is saved" do
    subject.save!

    expect(subject.members_context).to be_persisted
  end
end
