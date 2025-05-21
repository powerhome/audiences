# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::UsersObserver do
  before(:all) { Audiences::Scim::UsersObserver.start }
  after(:all) { Audiences::Scim::UsersObserver.stop }

  it "creates an external user" do
    params = { "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to change { Audiences::ExternalUser.count }.by(1)

    created_user = Audiences::ExternalUser.last

    expect(created_user.user_id).to eql "external-id-123"
    expect(created_user.data).to eql params
  end

  it "updates an existing external user on a CreateEvent" do
    user = Audiences::ExternalUser.create(user_id: "external-id-123", data: {})
    params = { "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to_not change { Audiences::ExternalUser.count }

    user.reload

    expect(user.user_id).to eql "external-id-123"
    expect(user.data).to eql params
  end

  it "updates an existing external user on an ReplaceEvent" do
    user = Audiences::ExternalUser.create(user_id: "external-id-123", data: {})
    params = { "displayName" => "My User", "externalId" => "external-id-123" }

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
    end.to_not change { Audiences::ExternalUser.count }

    user.reload

    expect(user.user_id).to eql "external-id-123"
    expect(user.data).to eql params
  end
end
