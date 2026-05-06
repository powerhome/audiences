# frozen_string_literal: true

class AddUniqueIndexToGroupMemberships < ActiveRecord::Migration[6.1]
  def change
    add_index :audiences_group_memberships,
              [:group_id, :external_user_id],
              unique: true,
              name: 'index_group_memberships_on_group_and_user'
  end
end
