# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ContextExtraUser do
  describe "source_user_id" do
    let(:column) { described_class.columns_hash["source_user_id"] }

    it "is a string column" do
      expect(column.type).to eq(:string)
    end

    it "allows null, so rows written before the backfill stay valid" do
      expect(column.null).to be(true)
    end

    it "is indexed" do
      expect(described_class.connection.index_exists?(described_class.table_name, :source_user_id)).to be(true)
    end

    it "holds the user's scim_id when saved through Context#extra_users=" do
      user = create_user
      context = create_context(extra_users: [user])

      expect(described_class.where(context: context).pluck(:source_user_id)).to eq([user.scim_id])
    end
  end
end
