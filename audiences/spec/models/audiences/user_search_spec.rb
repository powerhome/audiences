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
end
