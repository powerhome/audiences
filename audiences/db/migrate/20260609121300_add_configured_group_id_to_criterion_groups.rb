# frozen_string_literal: true

class AddConfiguredGroupIdToCriterionGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_criterion_groups, :configured_group_id, :integer
    add_index :audiences_criterion_groups, :configured_group_id
  end
end
