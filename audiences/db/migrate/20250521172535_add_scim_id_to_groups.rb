# frozen_string_literal: true

class AddScimIdToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_groups, :scim_id, :string
    add_index :audiences_groups, :scim_id, unique: true
  end
end
