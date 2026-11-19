# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::CriterionGroup do
  describe "source_group_id" do
    let(:column) { described_class.columns_hash["source_group_id"] }

    it "is a string column" do
      expect(column.type).to eq(:string)
    end

    it "allows null, so rows written before the backfill stay valid" do
      expect(column.null).to be(true)
    end

    it "is indexed" do
      expect(described_class.connection.index_exists?(described_class.table_name, :source_group_id)).to be(true)
    end

    it "holds the group's scim_id when saved through Criterion#groups=" do
      group = create_group
      criterion = create_criterion(groups: [group])

      expect(described_class.where(criterion: criterion).pluck(:source_group_id)).to eq([group.scim_id])
    end

    it "tracks the replacement group's scim_id when the join is reassigned" do
      original, replacement = create_groups(2)
      criterion = create_criterion(groups: [original])
      join = described_class.where(criterion: criterion).sole

      join.update!(group: replacement)

      expect(join.reload).to have_attributes(group_id: replacement.id, source_group_id: replacement.scim_id)
    end

    it "preserves both persisted references when reassignment fails" do
      group = create_group
      criterion = create_criterion(groups: [group])
      join = described_class.where(criterion: criterion).sole

      expect(join.update(group: nil)).to be(false)

      expect(join.reload).to have_attributes(group_id: group.id, source_group_id: group.scim_id)
    end
  end
end
