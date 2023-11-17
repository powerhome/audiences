# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
  end

  describe ".map([])" do
    it "builds contexts with the given " do
      criteria = Audiences::Criterion.map(
        [
          { groups: { Departments: [{ id: 1 }] } },
          { groups: { Territories: [{ id: 3 }] } },
        ]
      )

      expect(criteria.size).to eql 2
      expect(criteria.first.groups).to match({ "Departments" => [{ "id" => 1 }] })
      expect(criteria.last.groups).to match({ "Territories" => [{ "id" => 3 }] })
    end
  end
end
