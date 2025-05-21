# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::UsersObserver do
  before(:all) { Audiences::Scim::UsersObserver.start }
  after(:all) { Audiences::Scim::UsersObserver.stop }

  it "creates an external user" do
    params = { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to change { Audiences::ExternalUser.count }.by(1)

    created_user = Audiences::ExternalUser.last

    expect(created_user.scim_id).to eql "internal-id-123"
    expect(created_user.user_id).to eql "external-id-123"
    expect(created_user.data).to eql params
  end

  it "updates an existing external user on a CreateEvent" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {})
    params = { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-123"
    expect(user.data).to eql params
  end

  it "updates an existing external user on an ReplaceEvent" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123", user_id: "external-id-123", data: {})
    params = { "id" => "internal-id-123", "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-123"
    expect(user.data).to eql params
  end

  it "creates user with group memberships" do
    new_groups = [
      create_group("group-123"),
      create_group("group-456"),
      create_group("group-789"),
    ]
    params = {
      "id" => "internal-id-123",
      "displayName" => "My User",
      "externalId" => "external-id-123",
      "groups" => [
        { "value" => "group-123" },
        { "value" => "group-456" },
        { "value" => "group-789" },
      ]
    }

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
    end.to change { Audiences::ExternalUser.count }

    user = Audiences::ExternalUser.last

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-123"
    expect(user.groups).to match_array new_groups
    expect(user.data).to eql params
  end

  def create_group(scim_id)
    Audiences::Group.create!(scim_id: scim_id)
  end
end
