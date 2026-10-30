# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::CriterionGroup do
  describe "associations" do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:criterion) }
  end

  it "holds a configured reference alongside the legacy one" do
    criterion = create_criterion(groups: [create_group])
    criterion_group = criterion.criterion_groups.first

    criterion_group.update!(configured_group: ExampleSourceGroup.create!(display_name: "Engineering"))

    expect(criterion_group.reload.configured_group).to be_an(ExampleSourceGroup)
    expect(criterion_group.group).to be_an(Audiences::Group)
  end
end
