# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences/scim" do
  let(:resources) do
    [
      {
        schemas: ["schema:a", "schema:b"],
        meta: { location: "http://example.com/scim/v2/MyResources/1" },
        externalId: "1", displayName: "A Name", photos: "photo 1"
      },
      {
        schemas: ["schema:a", "schema:b"],
        meta: { location: "http://example.com/scim/v2/MyResources/2" },
        externalId: "2", displayName: "Another Name", photos: "photo 2"
      },
      {
        schemas: ["schema:a", "schema:b"],
        meta: { location: "http://example.com/scim/v2/MyResources/3" },
        externalId: "3", displayName: "YAN", photos: "photo 3"
      },
    ].as_json
  end
  let(:response_body) do
    { Resources: resources }.to_json
  end

  context "GET /audiences/scim" do
    it "returns the Resources key from the response" do
      attrs = "id,externalId,displayName"
      query = "attributes=#{attrs}&count&filter=name eq John&startIndex"
      stub_request(:get, "http://example.com/scim/v2/MyResources?#{query}")
        .to_return(status: 200, body: response_body, headers: {})

      get audience_scim_proxy_path(scim_path: "MyResources", filter: "name eq John")

      expect(response.parsed_body).to match([
                                              { "displayName" => "A Name", "externalId" => "1", "photos" => "photo 1" },
                                              { "displayName" => "Another Name", "externalId" => "2",
                                                "photos" => "photo 2" },
                                              { "displayName" => "YAN", "externalId" => "3", "photos" => "photo 3" },
                                            ])
    end

    it "returns 'count' resources" do
      attrs = "id,externalId,displayName"
      query = "attributes=#{attrs}&count=1&filter&startIndex"
      stub_request(:get, "http://example.com/scim/v2/MyResources?#{query}")
        .to_return(status: 200, body: { Resources: resources.slice(0, 1) }.to_json, headers: {})

      get audience_scim_proxy_path(scim_path: "MyResources", count: 1)

      expect(response.parsed_body).to match([{ "displayName" => "A Name", "externalId" => "1", "photos" => "photo 1" }])
    end

    it "returns resources starting from 'startIndex'" do
      attrs = "id,externalId,displayName"
      query = "attributes=#{attrs}&count&filter&startIndex=3"
      stub_request(:get, "http://example.com/scim/v2/MyResources?#{query}")
        .to_return(status: 200, body: { Resources: resources.slice(2, 1) }.to_json, headers: {})

      get audience_scim_proxy_path(scim_path: "MyResources", startIndex: 3)

      expect(response.parsed_body).to match([{ "displayName" => "YAN", "externalId" => "3", "photos" => "photo 3" }])
    end

    it "removes the schemas and meta from the resources" do
      attrs = "id,externalId,displayName"
      query = "attributes=#{attrs}&count&filter=name eq John&startIndex"
      stub_request(:get, "http://example.com/scim/v2/MyResources?#{query}")
        .to_return(status: 200, body: response_body, headers: {})

      get audience_scim_proxy_path(scim_path: "MyResources", filter: "name eq John")

      expect(response.parsed_body.pluck("schemas").compact).to be_empty
      expect(response.parsed_body.pluck("meta").compact).to be_empty
    end
  end
end
