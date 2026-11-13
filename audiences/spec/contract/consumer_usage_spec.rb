# frozen_string_literal: true

require "rails_helper"

# Pins the calls connect-server makes against the gem. The class and method names
# in the descriptions say where each call comes from.
RSpec.describe "Consumer usage of Audiences" do
  let(:group) { create_group(resource_type: "Groups") }
  let(:context) { create_context }
  let(:key) { context.signed_key }

  def reloaded_context
    Audiences::Context.find(context.id)
  end

  describe "reading an audience" do
    before do
      create_criterion(context: context, groups: [group])
      create_user(scim_id: "scim-user-1", groups: [group])
      create_user(scim_id: "scim-user-2", groups: [group])
    end

    it "gives records that carry the SCIM id in data (Room#subs)" do
      expect(reloaded_context.users.map { |user| user.data["id"] }).to match_array(%w[scim-user-1 scim-user-2])
    end

    it "counts the matching users (Client#fetch_users)" do
      expect(reloaded_context.count).to eql(2)
    end

    it "serializes the users under a users key (Client#fetch_users)" do
      json = JSON.parse({ "users" => reloaded_context.users }.to_json)

      expect(json["users"].map { |user| user["id"] }).to match_array(%w[scim-user-1 scim-user-2])
    end
  end

  describe "extra users (ExtraUsers)" do
    let!(:active_user) { create_user(scim_id: "active-user") }
    let!(:inactive_user) { create_user(scim_id: "inactive-user", active: false) }

    before { context.update!(extra_users: [active_user, inactive_user]) }

    it "includes inactive users" do
      expect(reloaded_context.extra_users).to match_array([active_user, inactive_user])
    end

    it "plucks scim ids" do
      expect(reloaded_context.extra_users.pluck(:scim_id)).to match_array([active_user.scim_id, inactive_user.scim_id])
    end

    it "yields records that respond to scim_id" do
      expect(reloaded_context.extra_users.map(&:scim_id)).to match_array([active_user.scim_id, inactive_user.scim_id])
    end

    it "adds an Array of records with +" do
      added = create_user(scim_id: "added-user")

      expect((reloaded_context.extra_users + [added]).map(&:scim_id))
        .to match_array([active_user.scim_id, inactive_user.scim_id, added.scim_id])
    end

    it "serializes with as_json" do
      expect(reloaded_context.extra_users.as_json.map { |json| json["id"] })
        .to match_array([active_user.scim_id, inactive_user.scim_id])
    end
  end

  describe "Audiences.update" do
    it "resolves a group by externalId only (ConnectAccessResolver.client_audience)" do
      updated = Audiences.update(key, criteria: [{ groups: { "Groups" => [{ externalId: group.external_id }] } }])

      expect(updated.criteria.flat_map(&:groups)).to eql([group])
    end

    it "sets match_all" do
      expect(Audiences.update(key, match_all: true)).to be_match_all
    end

    describe "a round trip of the current values (ExtraUsers#update_audience_context)" do
      let(:user) { create_user }
      let!(:previous) do
        create_criterion(context: context, groups: [group])
        context.update!(extra_users: [user])
        reloaded_context
      end

      before do
        Audiences.update(key, match_all: previous.match_all,
                              criteria: previous.criteria.as_json,
                              extra_users: previous.extra_users.as_json)
      end

      it "keeps match_all" do
        expect(reloaded_context.match_all).to eql(previous.match_all)
      end

      it "keeps the criteria's groups" do
        expect(reloaded_context.criteria.flat_map(&:groups)).to match_array(previous.criteria.flat_map(&:groups))
      end

      it "keeps the extra users" do
        expect(reloaded_context.extra_users).to match_array(previous.extra_users)
      end
    end
  end

  describe "rendering an audience (Api::RoomsController)" do
    before do
      create_criterion(context: context, groups: [group])
      context.update!(extra_users: [create_user])
    end

    let(:json) { JSON.parse({ context: reloaded_context, criteria: reloaded_context.criteria }.to_json) }

    it "renders the context keys" do
      expect(json["context"].keys).to match_array(%w[match_all count extra_users criteria])
    end

    it "renders the criterion keys" do
      expect(json["criteria"].first.keys).to match_array(%w[id count groups])
    end

    it "renders a criterion's groups by resource type" do
      expect(json["criteria"].first["groups"]).to eql("Groups" => [group.as_json])
    end
  end
end
