# frozen_string_literal: true

class CreateConfiguredUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :configured_users do |t|
      t.string :user_id
      t.string :display_name
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :configured_users, :user_id
  end
end
