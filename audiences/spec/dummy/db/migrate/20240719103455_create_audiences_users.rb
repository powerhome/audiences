# frozen_string_literal: true

class CreateAudiencesUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :example_users do |t|
      t.string :name

      t.timestamps
    end
  end
end
