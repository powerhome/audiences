# frozen_string_literal: true

class AddExtraUsersToAudiencesContext < ActiveRecord::Migration[6.0]
  def change
    add_column :audiences_contexts, :extra_users, :json
  end
end
