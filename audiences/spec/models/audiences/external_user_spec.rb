# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ExternalUser do
  describe ".search" do
    it "searches through any serialized data attribute" do
      john_doe = Audiences::ExternalUser.create(user_id: 123, data: { name: "John Doe" })
      frank_doe = Audiences::ExternalUser.create(user_id: 321, data: { name: "Frank Doe", territory: "Philadelphia" })

      john_search = Audiences::ExternalUser.search("John")
      phila_search = Audiences::ExternalUser.search("Phila")

      expect(john_search.count).to eql 1
      expect(john_search.first).to eql john_doe
      expect(phila_search.count).to eql 1
      expect(phila_search.first).to eql frank_doe
    end
  end

  describe "#map" do
    it "takes a list of user data and creates ExternalUser instances, returning them" do
      john, joseph, mary, steve, *others = Audiences::ExternalUser.wrap([
                                                                          { "id" => 123, "displayName" => "John Doe" },
                                                                          { "id" => 456,
                                                                            "displayName" => "Joseph Doe" },
                                                                          { "id" => 789, "displayName" => "Mary Doe" },
                                                                          { "id" => 987, "displayName" => "Steve Doe" },
                                                                        ])

      expect(others).to be_empty
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "id" => 123, "displayName" => "John Doe" })
      expect(joseph.user_id).to eql "456"
      expect(joseph.data).to match({ "id" => 456, "displayName" => "Joseph Doe" })
      expect(mary.user_id).to eql "789"
      expect(mary.data).to match({ "id" => 789, "displayName" => "Mary Doe" })
      expect(steve.user_id).to eql "987"
      expect(steve.data).to match({ "id" => 987, "displayName" => "Steve Doe" })
    end

    it "updates existing users" do
      joseph = Audiences::ExternalUser.create(user_id: 456, data: { "id" => 456, displayName: "Joseph F. Doe" })

      john, updated_joseph, *others = Audiences::ExternalUser.wrap([
                                                                     { "id" => 123,
                                                                       "displayName" => "John Doe" },
                                                                     { "id" => 456,
                                                                       "displayName" => "Joseph Doe" },
                                                                   ])

      expect(others).to be_empty
      expect(john.user_id).to eql "123"
      expect(john.data).to match({ "id" => 123, "displayName" => "John Doe" })

      expect(updated_joseph).to eql joseph.reload
      expect(updated_joseph.user_id).to eql "456"
      expect(updated_joseph.data).to match({ "id" => 456, "displayName" => "Joseph Doe" })
    end
  end
end
