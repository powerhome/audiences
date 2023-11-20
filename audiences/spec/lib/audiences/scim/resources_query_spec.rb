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
            .with(method: :Get, path: :Users, query: { page: 2 })
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
            .with(method: :Get, path: :Users, query: { page: 3 })
            .and_return("Resources" => [
                          { "id" => 555, "displayName" => "John Doe the 5th" },
                        ],
                        "totalResults" => 5,
                        "startIndex" => 5,
                        "itemsPerPage" => 2)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Users)

        expect(query.all.count).to eql 5
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

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups)

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

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups)

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

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups)

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

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Groups)

        expect(query.next_page?).to be false
      end
    end

    describe "#next_page" do
      it "is a similar ResourcesQuery object of the next page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { filters: "displayName eq John" })
            .and_return("totalResults" => 40,
                        "startIndex" => 1,
                        "itemsPerPage" => 25)
        )

        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Users, filters: "displayName eq John")
        next_page = query.next_page

        expect(next_page.query_options.delete(:page)).to eql 2
        expect(query.query_options).to eql(next_page.query_options)
      end

      it "is nil when there is no next page" do
        allow(client).to(
          receive(:perform_request)
            .with(method: :Get, path: :Users, query: { page: 2 })
            .and_return("totalResults" => 40,
                        "startIndex" => 26,
                        "itemsPerPage" => 25)
        )
        query = Audiences::Scim::ResourcesQuery.new(client, resource_type: :Users, page: 2)

        expect(query.next_page?).to be false
        expect(query.next_page).to be_nil
      end
    end
  end
end
