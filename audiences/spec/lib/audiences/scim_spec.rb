# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim do
  subject { Audiences::Scim.new(uri: "http://example.com/scim/") }

  context "#query" do
    let(:resources) do
      [
        { id: "13", displayName: "A Name", photos: "photo 1", anotherAttribute: "value" },
        { id: "2", displayName: "Another Name", photos: "photo 2", anotherAttribute: "value" },
        { id: "3", displayName: "YAN", photos: "photo 3", anotherAttribute: "value" },
      ]
    end
    let(:response_body) do
      { Resources: resources }.to_json
    end

    it "queries the scim backend for the given resource" do
      stub_request(:get, "http://example.com/scim/Users")
        .with(query: { filter: "name eq John" })
        .to_return(body: response_body, status: 201)

      users = subject.query("Users", filter: "name eq John")

      expect(users.size).to eql(3)
      expect(users.first).to be_a Audiences::SafeObject
      expect(users.first.id).to eql "13"
      expect(users.first.displayName).to eql "A Name"
      expect(users.first.photos).to eql "photo 1"
    end
  end
end
