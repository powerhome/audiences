# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Criterion do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
  end

  describe "validations" do
    it "does not allow criterion groups with empty groups" do
      criterion = Audiences::Criterion.new(groups: [])
      expect(criterion).not_to be_valid
      expect(criterion.errors[:groups]).to include("can't be blank")
    end
  end

  describe ".relevant_to" do
    it "returns criteria relevant to the given group" do
      group1, group2 = create_groups(2)
      criterion1 = create_criterion(groups: [group1])
      criterion2 = create_criterion(groups: [group2])
      criterion3 = create_criterion(groups: [group1, group2])
      create_criterion(groups: [])

      expect(Audiences::Criterion.relevant_to(group1)).to match_array [criterion1, criterion3]
      expect(Audiences::Criterion.relevant_to(group2)).to match_array [criterion2, criterion3]
    end
  end

  describe ".map([])" do
    it "builds contexts with the given " do
      department = create_group(resource_type: "Departments")
      territory = create_group(resource_type: "Territories")

      criteria = Audiences::Criterion.map(
        [
          { "groups" => { "Departments" => [department.as_json] } },
          { "groups" => { "Territories" => [territory.as_json] } },
        ]
      )

      expect(criteria.size).to eql 2
      expect(criteria.first.groups).to match_array [department]
      expect(criteria.last.groups).to match_array [territory]
    end

    it "allows setting creating groups not matching the default group scope" do
      department = create_group(resource_type: "Departments", scim_id: "123", active: false)

      criteria = Audiences::Criterion.map(
        [
          { "groups" => { "Departments" => [department.as_json] } },
        ]
      )

      expect(criteria.size).to eql 1
      expect(criteria.first.groups).to match_array([department])
    end
  end

  describe "#matching_users" do
    let(:source) { Audiences::Sources::Legacy.new }

    before { allow(Audiences).to receive(:source).and_return(source) }

    it "is none, without asking the source for users, when the criterion has no groups" do
      create_users(2)
      criterion = create_criterion(groups: [create_group])
      allow(source).to receive(:groups_of).and_return(Audiences::Group.none)
      allow(source).to receive(:users_matching).and_call_original

      expect(criterion.matching_users).to be_empty
      expect(source).not_to have_received(:users_matching)
    end

    it "asks the source for its groups once" do
      criterion = create_criterion(groups: [create_group])
      allow(source).to receive(:groups_of).and_call_original

      criterion.matching_users

      expect(source).to have_received(:groups_of).with(criterion).once
    end

    it "gives the source the groups it loaded" do
      group = create_group
      criterion = create_criterion(groups: [group])
      allow(source).to receive(:users_matching).and_call_original

      criterion.matching_users

      expect(source).to have_received(:users_matching).with(groups: [group])
    end

    it "gives the source loaded groups, not a relation" do
      criterion = create_criterion(groups: [create_group])
      allow(source).to receive(:users_matching).and_call_original

      criterion.matching_users

      expect(source).to have_received(:users_matching).with(groups: an_instance_of(Array))
    end

    it "is what the source returned" do
      user = create_user
      criterion = create_criterion(groups: [create_group])
      allow(source).to receive(:users_matching).and_return(Audiences::ExternalUser.where(id: user.id))

      expect(criterion.matching_users).to contain_exactly(user)
    end
  end

  describe "#users" do
    it "applies the default users scope to the matching users" do
      active_user = create_user
      inactive_user = create_user(active: false)
      group = create_group(external_users: [active_user, inactive_user])

      expect(create_criterion(groups: [group]).users).to contain_exactly(active_user)
    end
  end

  describe "#as_json" do
    let(:source) { Audiences::Sources::Legacy.new }

    before { allow(Audiences).to receive(:source).and_return(source) }

    it "reads the groups from the source" do
      other_group = create_group(resource_type: "Titles")
      criterion = create_criterion(groups: [create_group(resource_type: "Titles")])
      allow(source).to receive(:groups_of).with(criterion).and_return([other_group])

      expect(criterion.as_json["groups"]).to eql("Titles" => [other_group.as_json])
    end

    it "renders the groups of each type through the source" do
      criterion = create_criterion(groups: [create_group(resource_type: "Titles")])
      allow(source).to receive(:present).and_return([{ "rendered" => "by the source" }])

      expect(criterion.as_json["groups"]).to eql("Titles" => [{ "rendered" => "by the source" }])
    end
  end

  describe "#count" do
    it "is the count of member users" do
      users = create_users(2)
      criterion = Audiences::Criterion.new
      allow(criterion).to receive(:users) { users }

      expect(criterion.count).to eql 2
    end
  end
end
