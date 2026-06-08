# frozen_string_literal: true

class CreateConfiguredGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :configured_groups do |t|
      t.string :external_id
      t.string :display_name
      t.string :resource_type

      t.timestamps
    end

    add_index :configured_groups, :external_id
  end
end
