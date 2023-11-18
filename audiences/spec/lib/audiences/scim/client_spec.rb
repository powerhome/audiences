# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::Client do
  subject { Audiences::Scim::Client.new(uri: "http://example.com/scim/") }
  context "#perform_request" do
    let(:resources) do
      [
        { id: "13", displayName: "A Name", photos: "photo 1", anotherAttribute: "value" },
        { id: "2", displayName: "Another Name", photos: "photo 2", anotherAttribute: "value" },
        { id: "3", displayName: "YAN", photos: "photo 3", anotherAttribute: "value" },
      ]
    end
    let(:response_body) do
      { Resources: resources }
    end

    it "queries the scim backend for the given resource" do
      stub_request(:get, "http://example.com/scim/Users")
        .with(query: { filter: "name eq John" })
        .to_return(body: response_body.to_json, status: 201)

      response = subject.perform_request(path: :Users, method: :Get, query: { filter: "name eq John" })

      expect(response).to match(response_body.as_json)
    end
  end
end
