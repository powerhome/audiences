# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::UpsertGroupsObserver do
  before(:all) { Audiences::Scim::UpsertGroupsObserver.start }
  after(:all) { Audiences::Scim::UpsertGroupsObserver.stop }

  it "creates a group that is configured in Audiences.config.group_types" do
    params = { "id" => "internal-id-123", "displayName" => "My Group", "externalId" => "external-id-123" }
    expect do
      TwoPercent::CreateEvent.create(resource: "Groups", params: params)
    end.to change { Audiences::Group.count }.by(1)

    created_group = Audiences::Group.last

    expect(created_group.resource_type).to eql "Groups"
    expect(created_group.display_name).to eql "My Group"
    expect(created_group.scim_id).to eql "internal-id-123"
    expect(created_group.external_id).to eql "external-id-123"
  end

  it "updates a group that is configured in Audiences.config.group_types even with CreateEvent" do
    params = { "id" => "internal-id-123", "displayName" => "My Group", "externalId" => "external-id-123" }
    group = create_group("internal-id-123")

    expect do
      TwoPercent::CreateEvent.create(resource: "Groups", params: params)
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.display_name).to eql "My Group"
    expect(group.scim_id).to eql "internal-id-123"
    expect(group.external_id).to eql "external-id-123"
  end

  it "updates a group that is configured in Audiences.config.group_types" do
    params = { "id" => "internal-id-123", "displayName" => "My Group", "externalId" => "external-id-123" }
    group = create_group("internal-id-123")

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Groups", params: params)
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.display_name).to eql "My Group"
    expect(group.scim_id).to eql "internal-id-123"
    expect(group.external_id).to eql "external-id-123"
  end

  def create_group(scim_id)
    Audiences::Group.create!(scim_id: scim_id, display_name: "Group #{scim_id}",
                             external_id: scim_id, resource_type: "Groups")
  end
end
