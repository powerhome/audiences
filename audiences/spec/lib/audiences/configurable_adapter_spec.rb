# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ConfigurableAdapter do
  describe ".find_by_identifiers" do
    context "with legacy ExternalUser mode" do
      before do
        allow(Audiences.config).to receive(:use_configured_models).and_return(false)
      end

      it "finds users by id only" do
        user1 = create_legacy_user(user_id: "ext-123")
        user2 = create_legacy_user(user_id: "ext-456")
        create_legacy_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [user1.id, user2.id], external_ids: [])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by external_id only" do
        user1 = create_legacy_user(user_id: "ext-123")
        user2 = create_legacy_user(user_id: "ext-456")
        create_legacy_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [], external_ids: %w[ext-123 ext-456])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by both id and external_id" do
        user1 = create_legacy_user(user_id: "ext-123")
        user2 = create_legacy_user(user_id: "ext-456")
        create_legacy_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [user1.id], external_ids: ["ext-456"])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "returns none when both arrays are empty" do
        create_legacy_user(user_id: "ext-123")

        result = described_class.find_by_identifiers(ids: [], external_ids: [])

        expect(result).to be_empty
      end
    end

    context "with configured mode" do
      before do
        allow(Audiences.config).to receive(:use_configured_models).and_return(true)
        allow(Audiences.config).to receive(:user_model_class).and_return(ConfiguredUser)
      end

      it "finds users by id only" do
        user1 = create_configured_user(user_id: "ext-123")
        user2 = create_configured_user(user_id: "ext-456")
        create_configured_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [user1.id, user2.id], external_ids: [])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by external_id only" do
        user1 = create_configured_user(user_id: "ext-123")
        user2 = create_configured_user(user_id: "ext-456")
        create_configured_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [], external_ids: %w[ext-123 ext-456])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "finds users by both id and external_id" do
        user1 = create_configured_user(user_id: "ext-123")
        user2 = create_configured_user(user_id: "ext-456")
        create_configured_user(user_id: "ext-789")

        result = described_class.find_by_identifiers(ids: [user1.id], external_ids: ["ext-456"])

        expect(result.pluck(:id)).to match_array([user1.id, user2.id])
      end

      it "returns none when both arrays are empty" do
        create_configured_user(user_id: "ext-123")

        result = described_class.find_by_identifiers(ids: [], external_ids: [])

        expect(result).to be_empty
      end
    end
  end
end
