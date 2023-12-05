# frozen_string_literal: true

class CreateAudiencesExternalUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :audiences_external_users do |t|
      t.string :user_id
      t.json :data

      t.timestamps
    end
  end
end
