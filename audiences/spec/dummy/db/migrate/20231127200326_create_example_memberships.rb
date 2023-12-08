# frozen_string_literal: true

class CreateExampleMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :example_memberships do |t|
      t.belongs_to :owner, foreign_key: false
      t.integer :user_id
      t.string :name
      t.string :photo
      t.timestamps precision: 0
    end
  end
end
