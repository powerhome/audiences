# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences/scim", type: :request do
  let(:resources) do
    [
      { id: "1", displayName: "A Name", photo: "photo 1", anotherAttribute: "value" },
      { id: "2", displayName: "Another Name", photo: "photo 2", anotherAttribute: "value" },
      { id: "3", displayName: "YAN", photo: "photo 3", anotherAttribute: "value" },
    ]
  end
  let(:response_body) do
    { Resources: resources }.to_json
  end

  context "GET /audiences/scim" do
    it "returns the Resources key from the response" do
      stub_request(:get, "http://example.com/scim/v2/AnythingGoes")
        .with(query: { filter: "name eq John" })
        .to_return(body: response_body, status: 201)

      get audience_scim_proxy_path(scim_path: "AnythingGoes", filter: "name eq John")

      response_resources = response.parsed_body
      expect(response_resources.size).to eql(resources.size)
      expect(response_resources.first.keys).to match_array %w[id displayName photos]
    end

    it "proxies the headers" do
      stub_request(:get, "http://example.com/scim/v2/AnythingGoes?filter")
        .with(headers: { "Authorization" => "Bearer 123456789" })
        .to_return(body: response_body, status: 201)

      get audience_scim_proxy_path(scim_path: "AnythingGoes")

      response_resources = response.parsed_body
      expect(response_resources.size).to eql(resources.size)
    end
  end
end
