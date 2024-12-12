# frozen_string_literal: true

require "rails_helper"
require_relative "authenticated_endpoint_examples"

RSpec.describe Audiences::ScimProxyController do
  routes { Audiences::Engine.routes }

  context "GET /audiences/scim" do
    let(:resource_query) { double }
    before do
      allow(Audiences::Scim).to(
        receive(:resource)
          .with(:MyResources)
          .and_return(resource_query)
      )
    end

    it_behaves_like "authenticated endpoint" do
      subject { get :get }
    end

    it "returns the Resources key from the response" do
      allow(resource_query).to receive(:query).and_return({ "response" => "body" })

      get :get, params: { scim_path: "MyResources", filter: "name eq John" }

      expect(response.parsed_body).to eq({ "response" => "body" })
    end

    it "proxies queries with arguments" do
      expect(resource_query).to(
        receive(:query)
          .with(hash_including(filter: 'displayName co "John"', startIndex: "12", count: "21"))
          .and_return({ "response" => "body" })
      )

      get :get, params: { scim_path: "MyResources", count: 21, startIndex: 12, filter: "John" }

      expect(response.parsed_body).to eq({ "response" => "body" })
    end

    it "removes the schemas and meta from the resources" do
      allow(resource_query).to receive(:query).and_return({
                                                            "response" => "body",
                                                            "schemas" => ["schema:a"],
                                                            "meta" => "meta",
                                                          })

      get :get, params: { scim_path: "MyResources", filter: "name eq John" }

      expect(response.parsed_body).to eq({ "response" => "body" })
    end

    it "only fetches less sensitive attributes" do
      expect(resource_query).to(
        receive(:query)
          .with(hash_including(attributes: "id,externalId,displayName,photos"))
          .and_return({ "response" => "body" })
      )

      get :get, params: { scim_path: "MyResources", count: 21, startIndex: 12, filter: "name eq John" }

      expect(response.parsed_body).to eq({ "response" => "body" })
    end
  end
end
