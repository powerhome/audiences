# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim do
  describe ".resources" do
    it "applies the defaults to the given options" do
      Audiences::Scim.defaults[:Test] = { attributes: "id,photos" }

      query = Audiences::Scim.resources(type: :Test)

      expect(query.query_options).to eql({ attributes: "id,photos" })
    end

    it "applies the default attributes if no default is set" do
      query = Audiences::Scim.resources(type: :Anything)

      expect(query.query_options).to eql({ attributes: "id,externalId,displayName" })
    end
  end

  describe ".defaults" do
    it "limits the attributes to id and displayName by default" do
      expect(Audiences::Scim.defaults[:Anything]).to eql({ attributes: "id,externalId,displayName" })
    end
  end
end
