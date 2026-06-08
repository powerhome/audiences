# frozen_string_literal: true

class CreateConfiguredUserGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :configured_user_groups do |t|
      t.references :configured_user, null: false, foreign_key: true
      t.references :group, null: false

      t.timestamps
    end

    add_index :configured_user_groups, [:configured_user_id, :group_id], unique: true, name: "index_configured_user_groups_on_user_and_group"
  end
end
