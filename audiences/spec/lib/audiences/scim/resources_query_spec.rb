# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::ResourcesQuery do
  let(:client) { instance_double(Audiences::Scim::Client) }

  describe "data fetching" do
    it "is a collection of the resources returned by the query to scim" do
      allow(client).to(
        receive(:perform_request)
          .with(method: :Get, path: :Groups, query: {})
          .and_return("Resources" => [
                        { "id" => 123, "displayName" => "John Doe" },
                        { "id" => 123, "displayName" => "John Doe" },
                        { "id" => 123, "displayName" => "John Doe" },
                        { "id" => 123, "displayName" => "John Doe" },
                      ])
      )

      resources = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups).to_a

      expect(resources.size).to eql 4
      expect(resources.first.id).to eql 123
      expect(resources.first.displayName).to eql "John Doe"
    end

    it "wraps the resource objects with the given wrapper" do
      allow(client).to(
        receive(:perform_request)
          .with(method: :Get, path: :Groups, query: {})
          .and_return("Resources" => [
                        { "id" => 123, "displayName" => "John Doe" },
                      ])
      )

      new_wrapper = Struct.new(:data)

      resources = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups, wrapper: new_wrapper).to_a

      expect(resources.size).to eql 1
      expect(resources.first).to be_a new_wrapper
      expect(resources.first.data).to eql({ "id" => 123, "displayName" => "John Doe" })
    end
  end
end
