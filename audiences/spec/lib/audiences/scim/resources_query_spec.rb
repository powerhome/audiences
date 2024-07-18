# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::ResourcesQuery do
  let(:users_resource) { Audiences::Scim::Resource.new(type: :Users) }
  let(:groups_resource) { Audiences::Scim::Resource.new(type: :Groups) }
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

      resources = Audiences::Scim::ResourcesQuery.new(client, resource: groups_resource).to_a

      expect(resources.size).to eql 4
      expect(resources.first["id"]).to eql 123
      expect(resources.first["displayName"]).to eql "John Doe"
    end

    describe "fetching all" do
      it "iterates over all resources of all page starting from the current" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: {})
            .and_return("Resources" => [
                          { "id" => 111, "displayName" => "John Doe" },
                          { "id" => 222, "displayName" => "John Doe the 2nd" },
                        ],
                        "totalResults" => 5,
                        "startIndex" => 1,
                        "itemsPerPage" => 2)
        )
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { startIndex: 3,})
            .and_return("Resources" => [
                          { "id" => 333, "displayName" => "John Doe the 3rd" },
                          { "id" => 444, "displayName" => "John Doe the 4th" },
                        ],
                        "totalResults" => 5,
                        "startIndex" => 3,
                        "itemsPerPage" => 2)
        )
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { startIndex: 5,})
            .and_return("Resources" => [
                          { "id" => 555, "displayName" => "John Doe the 5th" },
                        ],
                        "totalResults" => 5,
                        "startIndex" => 5,
                        "itemsPerPage" => 2)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: users_resource)

        expect(query.all.count).to eql 5 # rubocop:disable Rails/RedundantActiveRecordAllMethod
      end
    end
  end

  context "pagination" do
    describe "#next_page?" do
      it "is true when the last possible index on the current page is before the last index in the last page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Groups, query: {})
            .and_return("totalResults" => 40,
                        "startIndex" => 1,
                        "itemsPerPage" => 25)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: groups_resource)

        expect(query.next_page?).to be true
      end

      it "is true when the last possible index on the current page is equal to total because startIndex is 1-based" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Groups, query: {})
            .and_return("totalResults" => 5,
                        "startIndex" => 3,
                        "itemsPerPage" => 2)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: groups_resource)

        expect(query.next_page?).to be true
      end

      it "is false when the last possible index on the current page is after the last index in the last page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Groups, query: {})
            .and_return("totalResults" => 40,
                        "startIndex" => 26,
                        "itemsPerPage" => 25)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: groups_resource)

        expect(query.next_page?).to be false
      end

      it "is false when the last possible index on the current page is the same the last index in the last page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Groups, query: {})
            .and_return("totalResults" => 50,
                        "startIndex" => 26,
                        "itemsPerPage" => 25)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: groups_resource)

        expect(query.next_page?).to be false
      end
    end

    describe "#next_page" do
      it "is a similar ResourcesQuery object of the next page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { filters: "displayName eq John",})
            .and_return("totalResults" => 40,
                        "startIndex" => 1,
                        "itemsPerPage" => 25)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource: users_resource, filters: "displayName eq John")
        next_page = query.next_page

        expect(next_page.options.delete(:startIndex)).to eql 26
        expect(query.options).to eql(next_page.options)
      end

      it "is nil when there is no next page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { startIndex: 26,})
            .and_return("totalResults" => 40,
                        "startIndex" => 26,
                        "itemsPerPage" => 25)
        )
        query = Audiences::Scim::ResourcesQuery.new(client, resource: users_resource, startIndex: 26)

        expect(query.next_page?).to be false
        expect(query.next_page).to be_nil
      end
    end
  end
end
