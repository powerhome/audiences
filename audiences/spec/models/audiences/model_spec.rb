# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Model do
  subject { ExampleOwner.new }

  describe "dynamic owner to audience relations" do
    it do
      is_expected.to have_one(:members_context).class_name("Audiences::Context")
    end
    it do
      is_expected.to have_many(:members_external_users).class_name("Audiences::ExternalUser")
                                                       .through(:members_context)
                                                       .source(:users)
    end
    it do
      is_expected.to have_many(:members).through(:members_external_users)
                                        .source(:identity)
    end
  end

  describe "dynamic scopes" do
    before { subject.save! }

    it "allows to eager load the members" do
      owner = ExampleOwner.with_members.first

      expect(owner.association(:members)).to be_loaded
    end

    it "allows to eager load the contexts" do
      owner = ExampleOwner.with_members_context.first

      expect(owner.association(:members_context)).to be_loaded
    end

    it "allows to eager load the external users" do
      owner = ExampleOwner.with_members_external_users.first

      expect(owner.association(:members_external_users)).to be_loaded
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
