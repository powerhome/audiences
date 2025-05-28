# frozen_string_literal: true

class AddDisplayNameToAudiencesExternalUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_external_users, :display_name, :string
    add_column :audiences_external_users, :picture_url, :string
  end
end
