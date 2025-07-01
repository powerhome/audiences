# frozen_string_literal: true

require "rails_helper"
require_relative "authenticated_endpoint_examples"

RSpec.describe Audiences::ScimProxyController do
  routes { Audiences::Engine.routes }

  context "GET /audiences/scim" do
    let(:resource_query) { double }

    it_behaves_like "authenticated endpoint" do
      subject { get :get }
    end

    it "returns the Resources key from the response" do
      group1 = create_group resource_type: "Groups", display_name: "Group Name 1"
      group2 = create_group resource_type: "Groups", display_name: "Group Name 2"
      create_group resource_type: "Groups", display_name: "Another thing"
      create_group resource_type: "Departments", display_name: "Department Name 3"

      get :get, params: { scim_path: "Groups", query: "Name" }

      expect(response.parsed_body).to match [group1, group2].as_json
    end

    it "can limit the results in a scim fashion" do
      create_group resource_type: "Groups"
      create_group resource_type: "Groups"
      group3 = create_group resource_type: "Groups"

      get :get, params: { scim_path: "Groups", count: 1, startIndex: 2 }

      expect(response.parsed_body).to match [group3].as_json
    end

    it "limits group resources by their default scope" do
      create_group resource_type: "Groups", active: false
      group2 = create_group resource_type: "Groups", active: true
      group3 = create_group resource_type: "Groups", active: true

      get :get, params: { scim_path: "Groups" }

      expect(response.parsed_body).to match [group2, group3].as_json
    end

    it "limits user resources by their default scope" do
      create_user active: false
      user2 = create_user active: true
      user3 = create_user active: true

      get :get, params: { scim_path: "Users" }

      expect(response.parsed_body).to match [user2, user3].as_json
    end
  end
end
