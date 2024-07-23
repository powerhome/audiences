# frozen_string_literal: true

class AddRelationToContext < ActiveRecord::Migration[6.1]
  def change
    add_column :audiences_contexts, :relation, :string, null: true
    remove_index :audiences_contexts, %w[owner_type owner_id], unique: true
    add_index :audiences_contexts, %w[owner_type owner_id relation],
              unique: true,
              name: "index_audiences_contexts_on_owner_type_owner_id_relation"
  end
end
