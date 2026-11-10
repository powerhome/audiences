# frozen_string_literal: true

class AddSourceGroupIdToAudiencesCriterionGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :audiences_criterion_groups, :source_group_id, :string
    add_index :audiences_criterion_groups, :source_group_id
  end
end
