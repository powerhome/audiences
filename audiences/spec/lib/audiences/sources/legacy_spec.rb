# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Sources::Legacy do
  subject(:source) { described_class.new }

  describe "#present" do
    it "renders a user the way the user model renders itself" do
      user = create_user(data: { "id" => "u-1", "displayName" => "Jane" })

      expect(source.present(user)).to eq(user.as_json)
    end

    it "renders a group the way the group model renders itself" do
      group = create_group(display_name: "Engineering")

      expect(source.present(group)).to eq(group.as_json)
    end
  end
end
