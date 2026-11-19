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
      user1, user2 = create_users(2)

      updated_context = Audiences.update(token, extra_users: [{ "id" => user1.scim_id }, { "id" => user2.scim_id }])
      expect(updated_context.extra_users).to match_array([user1, user2])
    end

    it "updates group criterion" do
      department1 = create_group(resource_type: "Departments")
      department2 = create_group(resource_type: "Departments")
      territory1 = create_group(resource_type: "Territories")
      territory2 = create_group(resource_type: "Territories")
      title1 = create_group(resource_type: "Titles")
      title2 = create_group(resource_type: "Titles")

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

    # Each row saved for a group or extra user keeps its legacy foreign key
    # (group_id, external_user_id) and also gets the source id (the scim_id).
    describe "the row saved for a group" do
      let(:group) { create_group(resource_type: "Departments") }

      def saved_row_referencing(reference)
        context = Audiences.update(token, criteria: [{ "groups" => { "Departments" => [reference] } }])
        Audiences::CriterionGroup.where(criterion: context.criteria).sole
      end

      it "has group_id and source_group_id when the group is referenced by id" do
        expect(saved_row_referencing("id" => group.scim_id))
          .to have_attributes(group_id: group.id, source_group_id: group.scim_id)
      end

      it "has group_id and source_group_id when the group is referenced by externalId only" do
        expect(saved_row_referencing("externalId" => group.external_id))
          .to have_attributes(group_id: group.id, source_group_id: group.scim_id)
      end
    end

    describe "the row saved for an extra user" do
      let(:user) { create_user }

      def saved_row_referencing(reference)
        context = Audiences.update(token, extra_users: [reference])
        Audiences::ContextExtraUser.where(context: context).sole
      end

      it "has external_user_id and source_user_id when the user is referenced by id" do
        expect(saved_row_referencing("id" => user.scim_id))
          .to have_attributes(external_user_id: user.id, source_user_id: user.scim_id)
      end

      it "has external_user_id and source_user_id when the user is referenced by externalId only" do
        expect(saved_row_referencing("externalId" => user.user_id))
          .to have_attributes(external_user_id: user.id, source_user_id: user.scim_id)
      end
    end

    describe "when match_all is true" do
      let(:match_all_context) { Audiences.update(token, match_all: true) }
      let(:user) { create_user }
      let(:group) { create_group(resource_type: "Departments") }

      before do
        Audiences.update(
          token,
          extra_users: [{ "id" => user.scim_id }],
          criteria: [{ "groups" => { "Departments" => [{ "id" => group.scim_id }] } }]
        )
      end

      it "clears the criteria" do
        expect(match_all_context.criteria).to be_empty
      end

      it "clears the extra users" do
        expect(match_all_context.extra_users).to be_empty
      end
    end
  end
end
