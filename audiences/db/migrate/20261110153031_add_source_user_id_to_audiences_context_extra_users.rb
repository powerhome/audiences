# frozen_string_literal: true

class AddSourceUserIdToAudiencesContextExtraUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :audiences_context_extra_users, :source_user_id, :string
    add_index :audiences_context_extra_users, :source_user_id
  end
end
