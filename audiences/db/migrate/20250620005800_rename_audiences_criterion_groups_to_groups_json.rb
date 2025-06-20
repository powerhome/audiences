# frozen_string_literal: true

class RenameAudiencesCriterionGroupsToGroupsJson < ActiveRecord::Migration[6.1]
  def change
    rename_column :audiences_criterions, :groups, :groups_json
  end
end
