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

  it "searches only the supplied users and counts matches before pagination" do
    members = create_users(3, data: { displayName: "Match" })
    create_user(data: { displayName: "Match" })
    scope = Audiences::ExternalUser.where(id: members).order(:id)

    search = described_class.new(scope: scope, query: "Match", limit: 1, offset: 1)

    expect(search.count).to eq(3)
    expect(search.users).to eq([members.second])
    expect(search.as_json).to eq(users: [members.second.as_json], count: 3)
  end

  it "uses the configured adapter to filter the supplied users without requiring a data column" do
    Audiences.config.source.use_configured = true
    jane = ExampleSourceUser.create!(display_name: "Jane Member")
    frank = ExampleSourceUser.create!(display_name: "Frank Member")
    ExampleSourceUser.create!(display_name: "Jane Outside")
    scope = ExampleSourceUser.where(id: [jane, frank])

    search = described_class.new(scope: scope, query: "Jane")

    expect(search.users).to eq([jane])
    expect(search.as_json).to eq(users: [jane.as_json], count: 1)
  end

  it "defaults to the selected source's users when no scope is supplied" do
    create_user(data: { displayName: "Jane Legacy" })
    jane = ExampleSourceUser.create!(display_name: "Jane Configured")
    Audiences.config.source.use_configured = true

    search = described_class.new(query: "Jane")

    expect(search.users).to eq([jane])
  end
end
