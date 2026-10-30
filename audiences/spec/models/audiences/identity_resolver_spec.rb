# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::IdentityResolver do
  subject(:resolver) { described_class.new }

  it "maps string source values to numeric host keys" do
    identity = ExampleUser.create!(name: "Host account")
    source_user = create_user(user_id: identity.id.to_s)
    users = Audiences::ExternalUser.where(id: source_user.id)

    expect(resolver.resolve(users: users)).to eq([identity])
  end

  it "looks up the configured host model by a non-primary identity key" do
    account = ExampleOwner.create!(name: "host-reference")
    source_user = create_user(user_id: account.name)
    users = Audiences::ExternalUser.where(id: source_user.id)
    allow(Audiences.config).to receive_messages(identity_class: "ExampleOwner", identity_key: :name)

    expect(resolver.resolve(users: users)).to eq([account])
  end

  it "preserves source order and repeated host identities" do
    first = ExampleUser.create!(name: "First account")
    second = ExampleUser.create!(name: "Second account")
    source_users = [
      create_user(user_id: second.id.to_s),
      create_user(user_id: first.id.to_s),
      create_user(user_id: "00#{second.id}"),
    ]
    users = Audiences::ExternalUser.where(id: source_users).order(:id)

    expect(resolver.resolve(users: users)).to eq([second, first, second])
  end

  it "returns nil when a source user has no matching host identity" do
    source_user = create_user(user_id: "missing-account")
    users = Audiences::ExternalUser.where(id: source_user.id)

    expect(resolver.resolve(users: users)).to eq([nil])
  end

  it "returns nil when the configured source supplies no identity value" do
    Audiences.config.source.use_configured = true
    source_user = ExampleSourceUser.create!(display_name: "Unmapped source user")
    users = ExampleSourceUser.where(id: source_user.id)

    expect(resolver.resolve(users: users)).to eq([nil])
  end

  it "returns an empty array for an empty membership scope" do
    expect(resolver.resolve(users: Audiences::ExternalUser.none)).to eq([])
  end

  it "loads host identities in one query rather than one per source user" do
    identities = Array.new(5) { |index| ExampleUser.create!(name: "Host account #{index}") }
    source_users = identities.map { |identity| create_user(user_id: identity.id.to_s) }
    users = Audiences::ExternalUser.where(id: source_users).order(:id)
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      sql = payload[:sql]
      queries << sql if sql.match?(/\ASELECT\b/i) && sql.include?(ExampleUser.table_name)
    end
    result = nil

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      result = resolver.resolve(users: users)
    end

    expect(result).to eq(identities)
    expect(queries.length).to eq(1)
  end
end
