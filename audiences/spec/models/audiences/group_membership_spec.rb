# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::GroupMembership do
  describe "associations" do
    it { is_expected.to belong_to(:external_user) }
    it { is_expected.to belong_to(:group) }
  end

  describe "after_commit callbacks" do
    let(:group) { create_group }
    let(:external_user) { create_user }

    it "publishes notifications for relevant contexts" do
      relevant_criterion = create_criterion(groups: [group])

      expect(Audiences::Notifications).to receive(:publish).with(relevant_criterion.context)

      Audiences::GroupMembership.create!(external_user: external_user, group: group)
    end
  end
end
