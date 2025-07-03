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
