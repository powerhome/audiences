# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences/scim" do
  let(:resources) do
    [
      { id: "1", displayName: "A Name", photos: "photo 1" },
      { id: "2", displayName: "Another Name", photos: "photo 2" },
      { id: "3", displayName: "YAN", photos: "photo 3" },
    ].as_json
  end
  let(:response_body) do
    { Resources: resources }.to_json
  end

  context "GET /audiences/scim" do
    it "returns the Resources key from the response" do
      stub_request(:get, "http://example.com/scim/v2/MyResources?filter=name eq John")
        .to_return(status: 200, body: response_body, headers: {})

      get audience_scim_proxy_path(scim_path: "MyResources", filter: "name eq John")

      expect(response.parsed_body).to match([
                                              { "displayName" => "A Name", "id" => "1", "photos" => "photo 1" },
                                              { "displayName" => "Another Name", "id" => "2", "photos" => "photo 2" },
                                              { "displayName" => "YAN", "id" => "3", "photos" => "photo 3" },
                                            ])
    end
  end
end
