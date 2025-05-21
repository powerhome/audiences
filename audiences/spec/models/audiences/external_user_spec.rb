# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser, :aggregate_failures do
  describe ".wrap" do
    it "takes a list of user data and creates ExternalUser instances, returning them" do
      john, joseph, mary, steve, *others = Audiences::ExternalUser.wrap([
                                                                          { "externalId" => 123,
                                                                            "displayName" => "John Doe" },
                                                                          { "externalId" => 456,
                                                                            "displayName" => "Joseph Doe" },
                                                                          { "externalId" => 789,
                                                                            "displayName" => "Mary Doe" },
                                                                          { "externalId" => 987,
                                                                            "displayName" => "Steve Doe" },
                                                                        ])

      expect(others).to be_empty
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "externalId" => 123, "displayName" => "John Doe" })
      expect(joseph.user_id).to eql "456"
      expect(joseph.data).to match({ "externalId" => 456, "displayName" => "Joseph Doe" })
      expect(mary.user_id).to eql "789"
      expect(mary.data).to match({ "externalId" => 789, "displayName" => "Mary Doe" })
      expect(steve.user_id).to eql "987"
      expect(steve.data).to match({ "externalId" => 987, "displayName" => "Steve Doe" })
    end

    it "updates existing users" do
      joseph = Audiences::ExternalUser.create(user_id: 456, data: { "externalId" => 456, displayName: "Joseph F. Doe" })
      user_data = [
        { "id" => "321", "externalId" => 123, "displayName" => "John Doe" },
        { "id" => "654", "externalId" => 456, "displayName" => "Joseph Doe" },
      ]

      john, updated_joseph, *others = Audiences::ExternalUser.wrap(user_data).order(:user_id)

      expect(others).to be_empty
      expect(john.scim_id).to eql "321"
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "id" => "321", "externalId" => 123, "displayName" => "John Doe" })

      expect(updated_joseph).to eql joseph.reload
      expect(updated_joseph.scim_id).to eql "654"
      expect(updated_joseph.user_id).to eql "456"
      expect(updated_joseph.data).to match({ "id" => "654", "externalId" => 456, "displayName" => "Joseph Doe" })
    end
  end
end
