# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::UpsertUsersObserver do
  before(:all) do
    Audiences::Scim::UpsertUsersObserver.start
    @old_required_user_group_types = Audiences.config.required_user_group_types
    Audiences.config.required_user_group_types = %w[Departments Titles Territories Roles]
  end

  after(:all) do
    Audiences.config.required_user_group_types = @old_required_user_group_types
    Audiences::Scim::UpsertUsersObserver.stop
  end

  before(:each) do
    create_group(scim_id: "group-1", resource_type: "Departments")
    create_group(scim_id: "group-2", resource_type: "Titles")
    create_group(scim_id: "group-3", resource_type: "Territories")
    create_group(scim_id: "group-4", resource_type: "Roles")
  end

  it "creates an external user having all required groups" do
    params = {
      "id" => "internal-id-123",
      "displayName" => "My User",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                   { "value" => "group-4" }],
    }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to change { Audiences::ExternalUser.count }.by(1)

    created_user = Audiences::ExternalUser.last

    expect(created_user.scim_id).to eql "internal-id-123"
    expect(created_user.user_id).to eql "external-id-123"
    expect(created_user.display_name).to eql "My User"
    expect(created_user.data).to eql params
    expect(created_user.active).to eql true
  end

  it "updates an existing external user on a CreateEvent having all required groups" do
    user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                           display_name: "Old Name", data: {}, active: false)
    params = {
      "id" => "internal-id-123",
      "displayName" => "New Name",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                   { "value" => "group-4" }],
    }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-123"
    expect(user.display_name).to eql "New Name"
    expect(user.data).to eql params
    expect(user.active).to eql true
  end

  it "updates an existing external user on a ReplaceEvent having all required groups" do
    user = Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                           display_name: "Old Name", data: {}, active: false)
    params = {
      "id" => "internal-id-123",
      "displayName" => "New Name",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-1" }, { "value" => "group-2" }, { "value" => "group-3" },
                   { "value" => "group-4" }],
    }

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-123"
    expect(user.display_name).to eql "New Name"
    expect(user.data).to eql params
    expect(user.active).to eql true
  end

  it "fails to create an external user not having all required groups" do
    params = {
      "id" => "internal-id-123",
      "displayName" => "My User",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
    }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to raise_error(Audiences::Scim::InvalidGroupsError)
  end

  it "fails to update an existing external user on a CreateEvent not having all required groups" do
    Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                    display_name: "Old Name", data: {}, active: false)
    params = {
      "id" => "internal-id-123",
      "displayName" => "New Name",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
    }

    expect do
      TwoPercent::CreateEvent.create(resource: "Users", params: params)
    end.to raise_error(Audiences::Scim::InvalidGroupsError)
  end

  it "fails to update an existing external user on a ReplaceEvent not having all required groups" do
    Audiences::ExternalUser.create!(scim_id: "internal-id-123", user_id: "external-id-123",
                                    display_name: "Old Name", data: {}, active: false)
    params = {
      "id" => "internal-id-123",
      "displayName" => "New Name",
      "externalId" => "external-id-123",
      "active" => true,
      "groups" => [{ "value" => "group-2" }, { "value" => "group-3" }, { "value" => "group-4" }],
    }

    expect do
      TwoPercent::ReplaceEvent.create(resource: "Users", params: params)
    end.to raise_error(Audiences::Scim::InvalidGroupsError)
  end
end
