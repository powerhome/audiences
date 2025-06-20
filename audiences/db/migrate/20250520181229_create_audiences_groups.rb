# frozen_string_literal: true

class CreateAudiencesGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :audiences_groups do |t|
      t.string :external_id
      t.string :scim_id
      t.string :display_name
      t.string :resource_type

      t.timestamps

      t.index %i[resource_type external_id], unique: true
      t.index %i[resource_type scim_id], unique: true
    end
  end
end
