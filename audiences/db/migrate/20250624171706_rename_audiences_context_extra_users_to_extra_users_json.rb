# frozen_string_literal: true

class RenameAudiencesContextExtraUsersToExtraUsersJson < ActiveRecord::Migration[6.1]
  def change
    rename_column :audiences_contexts, :extra_users, :extra_users_json
  end
end
