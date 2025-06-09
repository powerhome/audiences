# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::PatchGroupsObserver do
  before(:all) { Audiences::Scim::PatchGroupsObserver.start }
  after(:all) { Audiences::Scim::PatchGroupsObserver.stop }

  it "patches displayName" do
    group = create_group

    expect do
      TwoPercent::UpdateEvent.create(resource: "Groups",
                                     id: group.scim_id,
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "displayName",
                                           "value" => "New Name",
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.display_name).to eql "New Name"
  end

  it "patches externalId" do
    group = create_group

    expect do
      TwoPercent::UpdateEvent.create(resource: "Groups",
                                     id: group.scim_id,
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "externalId",
                                           "value" => "external-id-321",
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::Group.count })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.external_id).to eql "external-id-321"
  end

  it "adds group members" do
    member = Audiences::ExternalUser.create(scim_id: "123", user_id: 1)
    new_member = Audiences::ExternalUser.create(scim_id: "321", user_id: 2)
    group = create_group(external_users: [member])

    TwoPercent::UpdateEvent.create(resource: "Groups",
                                   id: group.scim_id,
                                   params: {
                                     "Operations" => [
                                       {
                                         "op" => "add",
                                         "path" => "members",
                                         "value" => [{ "value" => new_member.user_id }],
                                       },
                                     ],
                                   })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.external_users).to match_array [member, new_member]
  end

  it "removes group members" do
    member = Audiences::ExternalUser.create(scim_id: "123", user_id: 1)
    new_member = Audiences::ExternalUser.create(scim_id: "321", user_id: 2)
    group = create_group(external_users: [member, new_member])

    TwoPercent::UpdateEvent.create(resource: "Groups",
                                   id: group.scim_id,
                                   params: {
                                     "Operations" => [
                                       {
                                         "op" => "remove",
                                         "path" => "members",
                                         "value" => [{ "value" => new_member.user_id }],
                                       },
                                     ],
                                   })

    group.reload

    expect(group.resource_type).to eql "Groups"
    expect(group.external_users).to match_array [member]
  end
end
