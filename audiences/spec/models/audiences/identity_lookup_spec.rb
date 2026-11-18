# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::IdentityLookup do
  describe "#identities_of" do
    subject(:lookup) do
      described_class.new(identity_class: ExampleUser,
                          identity_key: identity_key,
                          source: source)
    end

    let(:identity_key) { :id }
    let(:source) { Audiences::Sources::Legacy.new }

    it "matches integer identities to string references and preserves missing entries in order" do
      first = ExampleUser.create!(name: "First")
      second = ExampleUser.create!(name: "Second")
      users = [
        create_user(user_id: second.id),
        create_user(user_id: first.id + second.id),
        create_user(user_id: first.id),
      ]

      expect(lookup.identities_of(users)).to eql [second, nil, first]
    end

    it "does not match an integer key with trailing characters" do
      identity = ExampleUser.create!(name: "Identity")
      user = create_user(user_id: "#{identity.id}abc")

      expect(lookup.identities_of([user])).to eql [nil]
    end

    it "does not match an integer key with leading zeroes" do
      identity = ExampleUser.create!(name: "Identity")
      user = create_user(user_id: "0#{identity.id}")

      expect(lookup.identities_of([user])).to eql [nil]
    end

    it "finds identities with a String identity key using the Legacy source" do
      identity = ExampleUser.create!(name: "alice")
      user = create_user(user_id: identity.name)
      lookup = described_class.new(identity_class: ExampleUser,
                                   identity_key: "name",
                                   source: Audiences::Sources::Legacy.new)

      expect(lookup.identities_of([user])).to eql [identity]
    end

    context "when the source returns a nil key" do
      let(:identity_key) { :name }
      let(:source) { double("source", identity_keys: [nil, ""]) }

      it "does not match a nil key to an empty string identity" do
        identity = ExampleUser.create!(name: "")
        users = Array.new(2) { Object.new }

        expect(lookup.identities_of(users)).to eql [nil, identity]
      end
    end
  end
end
