# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calculating through a configured source" do
  around do |example|
    default = Audiences.config.source
    Audiences.config.source = Audiences::Test::ExampleSource.new
    example.run
  ensure
    Audiences.config.source = default
  end

  it "matches every user of the configured source, not the projection" do
    create_user
    source_user = ExampleSourceUser.create!(display_name: "Jane Doe")

    context = create_context(match_all: true)

    expect(context.users).to eq([source_user])
  end

  it "matches a criterion's users through the configured source" do
    create_user
    group = ExampleSourceGroup.create!(display_name: "Engineering", resource_type: "Groups")
    member = ExampleSourceUser.create!(display_name: "Member")
    ExampleSourceMembership.create!(example_source_user: member, example_source_group: group)

    criterion = create_criterion(groups: [create_group])
    criterion.criterion_groups.first.update!(configured_group: group)

    expect(criterion.users).to eq([member])
  end

  it "unions a context's extra users with its criteria on the configured source" do
    group = ExampleSourceGroup.create!(display_name: "Engineering", resource_type: "Groups")
    member = ExampleSourceUser.create!(display_name: "Member")
    ExampleSourceMembership.create!(example_source_user: member, example_source_group: group)
    extra = ExampleSourceUser.create!(display_name: "Extra")

    context = create_context
    criterion = context.criteria.create!(groups: [create_group])
    criterion.criterion_groups.first.update!(configured_group: group)
    context.context_extra_users.create!(external_user: create_user, configured_user: extra)

    expect(context.users).to match_array([extra, member])
  end
end
