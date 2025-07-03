# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Group, :aggregate_failures do
  describe "associations" do
    it { is_expected.to have_many(:group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:external_users).through(:group_memberships).dependent(:destroy) }
  end

  describe ".search(query)" do
    it "returns users matching the query" do
      group1 = create_group(display_name: "Gropu Abc")
      group2 = create_group(display_name: "Gropu LOL")
      group3 = create_group(display_name: "Gropu YEY")

      results = Audiences::Group.search("LOL")

      expect(results).to contain_exactly(group2)
      expect(results).not_to include(group1, group3)
    end

    it "performs a case insensitive search" do
      group1 = create_group(display_name: "Gropu Abc")
      group2 = create_group(display_name: "Gropu LOL")
      group3 = create_group(display_name: "Gropu Abc")

      results = Audiences::Group.search("lol")

      expect(results).to contain_exactly(group2)
      expect(results).not_to include(group1, group3)
    end
  end
end
