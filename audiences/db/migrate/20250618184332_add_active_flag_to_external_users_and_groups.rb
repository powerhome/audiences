# frozen_string_literal: true

class AddActiveFlagToExternalUsersAndGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_external_users, :active, :boolean, default: true, null: false
    add_column :audiences_groups, :active, :boolean, default: true, null: false
  end
end
