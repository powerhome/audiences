# frozen_string_literal: true

class CreateAudiencesCriterionGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :audiences_criterion_groups do |t|
      t.references :criterion, foreign_key: false
      t.references :group, foreign_key: false

      t.timestamps
    end
  end
end
