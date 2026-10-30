# frozen_string_literal: true

class CreateExampleSourceRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :example_source_groups do |t|
      t.string :display_name
      t.string :resource_type

      t.timestamps
    end

    create_table :example_source_users do |t|
      t.string :display_name

      t.timestamps
    end
  end
end
