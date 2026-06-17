# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Integrations::UpsertGroupsObserver do
  before(:all) { Audiences::Integrations::UpsertGroupsObserver.start }
  after(:all) { Audiences::Integrations::UpsertGroupsObserver.stop }

  it "creates a group that is configured in Audiences.config.group_types" do
    group_attributes = {
      scim_id: "internal-id-123",
      display_name: "My Group",
      external_id: "external-id-123",
      active: true,
    }

    expect do
      TestDomainEvents::GroupCreated.create(
        group_attributes: group_attributes,
        resource_type: "Groups",
        correlation_id: "test-correlation-id"
      )
    end.to change { Audiences::Group.count }.by(1)

    created_group = Audiences::Group.last

    expect(created_group.resource_type).to eql "Groups"
    expect(created_group.display_name).to eql "My Group"
    expect(created_group.scim_id).to eql "internal-id-123"
    expect(created_group.external_id).to eql "external-id-123"
    expect(created_group.active).to eql true
  end

  it "updates a group that is configured in Audiences.config.group_types even with CreateEvent" do
    group = create_group
    group_attributes = {
      scim_id: group.scim_id,
      display_name: "My Group",
      external_id: "external-id-123",
      active: false,
    }

    expect do
      TestDomainEvents::GroupCreated.create(
        group_attributes: group_attributes,
        resource_type: "Groups",
        correlation_id: "test-correlation-id"
      )
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.display_name).to eql "My Group"
    expect(group.scim_id).to eql group.scim_id
    expect(group.external_id).to eql "external-id-123"
    expect(group.active).to eql false
  end

  it "updates a group that is configured in Audiences.config.group_types" do
    group = create_group
    group_attributes = {
      scim_id: group.scim_id,
      display_name: "My Group",
      external_id: "external-id-123",
      active: false,
    }

    expect do
      TestDomainEvents::GroupUpdated.create(
        group_attributes: group_attributes,
        resource_type: "Groups",
        correlation_id: "test-correlation-id"
      )
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.display_name).to eql "My Group"
    expect(group.scim_id).to eql group.scim_id
    expect(group.external_id).to eql "external-id-123"
    expect(group.active).to eql false
  end
end
