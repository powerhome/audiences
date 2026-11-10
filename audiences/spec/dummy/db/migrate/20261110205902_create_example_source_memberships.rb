# frozen_string_literal: true

class CreateExampleSourceMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :example_source_memberships do |t|
      t.references :example_source_user, null: false, foreign_key: false
      t.references :example_source_group, null: false, foreign_key: false

      t.timestamps
    end
  end
end
