# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Scim do
  describe ".resources" do
    it "fetches the resource definition by the type key" do
      Audiences.config.resources[:Test] = Audiences::Scim::Resource.new(type: :Test, attributes: %w[photos])

      resource = Audiences::Scim.resource(:Test)

      expect(resource.type).to be :Test
      expect(resource.attributes).to match_array %w[id externalId displayName photos]
    end

    it "creates a new resource definition when one doesn't exist" do
      resource = Audiences::Scim.resource(:Anything)

      expect(resource.type).to be :Anything
    end
  end
end
