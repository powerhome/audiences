# frozen_string_literal: true

class CreateExampleSourceGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :example_source_groups do |t|
      t.string :display_name
      t.string :resource_type

      t.timestamps
    end
  end
end
