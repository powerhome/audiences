# frozen_string_literal: true

class CreateAudiencesAudiencesResources < ActiveRecord::Migration[6.0]
  def change
    create_table :audiences_resources do |t|
      t.integer :resource_id
      t.string :display
      t.string :image_url
      t.string :resource_type

      t.timestamps
    end
  end
end
