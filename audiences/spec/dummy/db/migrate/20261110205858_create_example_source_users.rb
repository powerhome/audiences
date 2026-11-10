# frozen_string_literal: true

class CreateExampleSourceUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :example_source_users do |t|
      t.string :display_name

      t.timestamps
    end
  end
end
