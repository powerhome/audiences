# frozen_string_literal: true

class CreateExampleSourceMemberships < ActiveRecord::Migration[6.1]
  def change
    create_table :example_source_memberships do |t|
      t.references :example_source_user, foreign_key: false
      t.references :example_source_group, foreign_key: false

      t.timestamps
    end
  end
end
