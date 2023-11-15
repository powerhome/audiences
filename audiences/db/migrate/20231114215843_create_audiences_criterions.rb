# frozen_string_literal: true

class CreateAudiencesCriterions < ActiveRecord::Migration[6.0]
  def change
    create_table :audiences_criterions do |t|
      t.json :groups
      t.references :context, null: false, foreign_key: { to_table: :audiences_contexts }

      t.timestamps
    end
  end
end
