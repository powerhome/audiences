# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences do
  describe ".update" do
    let(:baseball_club) { ExampleOwner.create(name: "Baseball Club") }
    let(:token) { Audiences::Context.for(baseball_club).signed_key }

    before do
      Audiences.config.user_model_class = "ConfiguredUser"
      Audiences.config.use_configured_models = true
    end

    after do
      Audiences.config.user_model_class = nil
      Audiences.config.use_configured_models = false
    end

    it "updates an audience context from a given key and params" do
      updated_context = Audiences.update(token, match_all: true)

      expect(updated_context).to be_match_all
    end

    it "updates extra users fetching latest information" do
      user1, user2 = create_users(2)

      updated_context = Audiences.update(token, extra_users: [{ "id" => user1.id }, { "id" => user2.id }])
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
          { "groups" => { "Departments" => [{ "id" => department1.id }, { "id" => department2.id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(1)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2]

      updated_context = Audiences.update(
        token,
        criteria: [
          { "groups" => { "Departments" => [{ "id" => department1.id }, { "id" => department2.id }],
                          "Territories" => [{ "id" => territory1.id }, { "id" => territory2.id }] } },
          { "groups" => { "Titles" => [{ "id" => title1.id }, { "id" => title2.id }] } },
        ]
      )

      expect(updated_context.criteria.size).to eql(2)
      expect(updated_context.criteria.first.groups).to match_array [department1, department2, territory1, territory2]
      expect(updated_context.criteria.last.groups).to match_array [title1, title2]
    end
  end
end
