# frozen_string_literal: true

class AddConfiguredUserIdToContextExtraUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_context_extra_users, :configured_user_id, :integer
    add_index :audiences_context_extra_users, :configured_user_id
  end
end
