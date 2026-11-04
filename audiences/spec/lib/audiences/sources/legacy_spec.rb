# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Sources::Legacy do
  subject(:source) { described_class.new }

  describe "#users_matching" do
    it "does not match every user when the criterion's groups are removed while matching" do
      user1, user2, user3 = create_users(3)
      title = create_group(resource_type: "Titles", external_users: [user1])
      criterion = Audiences::Criterion.find(create_criterion(groups: [title]).id)

      # Simulates a concurrent context update replacing the criteria right after
      # the first read of this criterion's groups.
      removed = false
      remove_groups = ->(*, payload) do
        next if removed || payload[:sql].exclude?("audiences_criterion_groups")

        removed = true
        Audiences::CriterionGroup.where(criterion_id: criterion.id).delete_all
      end

      users = ActiveSupport::Notifications.subscribed(remove_groups, "sql.active_record") do
        source.users_matching(groups: source.groups_of(criterion)).to_a
      end

      expect(removed).to be true
      expect(users).not_to include(user2, user3)
    end
  end

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
