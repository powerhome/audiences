# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences do
  describe ".update" do
    let(:baseball_club) { ExampleOwner.create(name: "Baseball Club") }
    let(:token) { Audiences::Context.for(baseball_club).signed_key }

    it "updates an audience context from a given key and params" do
      updated_context = Audiences.update(token, match_all: true)

      expect(updated_context).to be_match_all
    end

    it "updates extra users fetching latest information" do
      user1, user2 = create_paired_users(2)

      updated_context = Audiences.update(token, extra_users: [{ "id" => user1.scim_id }, { "id" => user2.scim_id }])
      expect(updated_context.extra_users).to match_array([user1, user2])
    end

    it "updates group criterion" do
      department1 = create_paired_group(resource_type: "Departments")
      department2 = create_paired_group(resource_type: "Departments")
      territory1 = create_paired_group(resource_type: "Territories")
      territory2 = create_paired_group(resource_type: "Territories")
      title1 = create_paired_group(resource_type: "Titles")
      title2 = create_paired_group(resource_type: "Titles")

      updated_context = Audiences.update(
        token,
        criteria: [
          { "groups" => { "Departments" => [{ "id" => department1.scim_id }, { "id" => department2.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2]

      updated_context = Audiences.update(
        token,
        criteria: [
          { "groups" => { "Departments" => [{ "id" => department1.scim_id }, { "id" => department2.scim_id }],
                          "Territories" => [{ "id" => territory1.scim_id }, { "id" => territory2.scim_id }] } },
          { "groups" => { "Titles" => [{ "id" => title1.scim_id }, { "id" => title2.scim_id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2, territory1, territory2]
      expect(updated_context.criteria.last.groups).to match_array [title1, title2]
    end
    context "with dual-written selections" do
      let(:source) { Audiences::Test::ExampleSelector.new }
      let(:group) { ExampleSourceGroup.create!(display_name: "Engineering", resource_type: "Departments") }
      let(:extra) { ExampleSourceUser.create!(display_name: "Extra") }
      let(:legacy_group) { create_group(resource_type: "Departments", scim_id: group.id) }
      let(:legacy_extra) { create_user(scim_id: extra.id) }
      let(:criteria) { [{ groups: { Departments: [{ id: group.id }] } }] }

      before do
        allow(Audiences).to receive(:source).and_return(source)
        legacy_group
        legacy_extra
      end

      [false, true].each do |use_configured|
        it "saves both references when membership reads use #{use_configured ? 'the configured source' : 'Legacy'}" do
          source.use_configured = use_configured

          updated = Audiences.update(token, criteria: criteria, extra_users: [{ id: extra.id }]).reload

          group_selection = updated.criteria.sole.criterion_groups.sole
          user_selection = updated.context_extra_users.sole
          expect(group_selection.group).to eq(legacy_group)
          expect(group_selection.configured_group).to eq(group)
          expect(user_selection.external_user).to eq(legacy_extra)
          expect(user_selection.configured_user).to eq(extra)
        end
      end

      it "keeps the previous selections when a replacement extra user cannot resolve" do
        original = Audiences.update(token, criteria: criteria, extra_users: [{ id: extra.id }])
        replacement = ExampleSourceGroup.create!(display_name: "Sales", resource_type: "Departments")
        create_group(resource_type: "Departments", scim_id: replacement.id)

        expect do
          Audiences.update(
            token,
            criteria: [{ groups: { Departments: [{ id: replacement.id }] } }],
            extra_users: [{ id: "missing" }]
          )
        end.to raise_error(ActiveRecord::RecordNotFound)

        expect(original.reload.criteria.sole.groups).to eq([legacy_group])
        expect(original.criteria.sole.criterion_groups.sole.configured_group).to eq(group)
        expect(original.extra_users).to eq([legacy_extra])
        expect(original.context_extra_users.sole.configured_user).to eq(extra)
      end

      it "rolls back replaced extra users when the new criterion fails validation" do
        original = Audiences.update(token, criteria: criteria, extra_users: [{ id: extra.id }])
        replacement = ExampleSourceUser.create!(display_name: "Replacement")
        create_user(scim_id: replacement.id)

        expect do
          Audiences.update(token, criteria: [{ groups: {} }], extra_users: [{ id: replacement.id }])
        end.to raise_error(ActiveRecord::RecordNotSaved)

        expect(original.reload.extra_users).to eq([legacy_extra])
        expect(original.context_extra_users.sole.configured_user).to eq(extra)
        expect(original.criteria.sole.groups).to eq([legacy_group])
      end
    end
  end
end
