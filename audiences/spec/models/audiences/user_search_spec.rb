# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::UsersSearch do
  it "searches through any serialized data attribute" do
    john_doe = Audiences::ExternalUser.create(
      user_id: 123,
      data: { displayName: "John Doe" }
    )
    frank_doe = Audiences::ExternalUser.create(
      user_id: 321,
      data: { displayName: "Frank Doe", territory: "Philadelphia" }
    )

    john_search = Audiences::UsersSearch.new(query: "John")
    phila_search = Audiences::UsersSearch.new(query: "Phila")

    expect(john_search.count).to eql 1
    expect(john_search.users.first).to eql john_doe
    expect(phila_search.count).to eql 1
    expect(phila_search.users.first).to eql frank_doe
  end

  describe "through the source" do
    let(:source) { Audiences::Sources::Legacy.new }
    let(:john) { Audiences::ExternalUser.create(user_id: 123, data: { displayName: "John Doe" }) }

    before do
      john
      Audiences::ExternalUser.create(user_id: 321, data: { displayName: "Frank Doe" })
      allow(Audiences).to receive(:source).and_return(source)
    end

    it "asks the source to narrow the scope by the query" do
      allow(source).to receive(:search_users).and_call_original
      scope = Audiences::ExternalUser.all

      Audiences::UsersSearch.new(query: "John", scope: scope).count

      expect(source).to have_received(:search_users).with(scope, "John")
    end

    it "searches the source's users when no scope is given" do
      allow(Audiences).to receive(:source).and_return(FakeSource.new)
      source_user = ExampleSourceUser.create!(display_name: "Jane Doe")

      search = Audiences::UsersSearch.new(query: "Doe")

      expect(search.users).to contain_exactly(source_user)
    end

    it "uses the users the source returned" do
      allow(source).to receive(:search_users).and_return(Audiences::ExternalUser.where(id: john.id))

      search = Audiences::UsersSearch.new(query: "anything")

      expect(search.users).to contain_exactly(john)
    end

    it "still applies the limit and the offset to the source's users" do
      allow(source).to receive(:search_users).and_return(Audiences::ExternalUser.order(:id))

      search = Audiences::UsersSearch.new(query: "Doe", limit: 1, offset: 1)

      expect(search.users.map(&:user_id)).to eql ["321"]
    end

    it "renders the users as the source presents them" do
      allow(source).to receive(:present).and_return([{ "id" => "presented" }])

      search = Audiences::UsersSearch.new(query: "John")

      expect(search.as_json).to eql(users: [{ "id" => "presented" }], count: 1)
    end

    it "asks the source to present only the users of the requested page" do
      allow(source).to receive(:present).and_call_original

      search = Audiences::UsersSearch.new(query: "Doe", limit: 1)
      search.as_json

      expect(source).to have_received(:present).with(search.users)
    end
  end
end
