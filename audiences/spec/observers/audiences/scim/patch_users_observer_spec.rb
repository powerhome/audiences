# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim::PatchUsersObserver do
  before(:all) { Audiences::Scim::PatchUsersObserver.start }
  after(:all) { Audiences::Scim::PatchUsersObserver.stop }

  it "patches externalId" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123",
                                          user_id: "external-id-123")

    expect do
      TwoPercent::UpdateEvent.create(resource: "Users",
                                     id: "internal-id-123",
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "externalId",
                                           "value" => "external-id-321",
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-321"
  end

  it "patches displayName" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123",
                                          user_id: "external-id-123",
                                          display_name: "Old John")

    expect do
      TwoPercent::UpdateEvent.create(resource: "Users",
                                     id: "internal-id-123",
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "displayName",
                                           "value" => "New John",
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.display_name).to eql "New John"
  end

  it "patches picture_url" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123",
                                          user_id: "external-id-123",
                                          picture_url: "https://example.com/my/pic")

    expect do
      TwoPercent::UpdateEvent.create(resource: "Users",
                                     id: "internal-id-123",
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "photos",
                                           "value" => [{ "value" => "https://example.com/another/pic" }],
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.picture_url).to eql "https://example.com/another/pic"
  end

  it "updates the External User data" do
    user = Audiences::ExternalUser.create(scim_id: "internal-id-123",
                                          user_id: "external-id-123",
                                          data: {
                                            "externalId" => "external-id-123",
                                            "name" => { "givenName" => "John", "familyName" => "Doe" },
                                          })

    expect do
      TwoPercent::UpdateEvent.create(resource: "Users",
                                     id: "internal-id-123",
                                     params: {
                                       "Operations" => [
                                         {
                                           "op" => "replace",
                                           "path" => "externalId",
                                           "value" => "external-id-321",
                                         },
                                         {
                                           "op" => "replace",
                                           "path" => "name.givenName",
                                           "value" => "Sir John",
                                         },
                                       ],
                                     })
    end.to_not(change { Audiences::ExternalUser.count })

    user.reload

    expect(user.scim_id).to eql "internal-id-123"
    expect(user.user_id).to eql "external-id-321"
    expect(user.data).to eql("externalId" => "external-id-321",
                             "name" => { "givenName" => "Sir John",
                                         "familyName" => "Doe" })
  end
end
