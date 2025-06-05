# frozen_string_literal: true

class AddScimIdToAudiencesExternalUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_external_users, :scim_id, :string
    add_index :audiences_external_users, :scim_id, unique: true
  end
end
