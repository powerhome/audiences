# frozen_string_literal: true

class CreateJoinTableAudiencesContextsAudiencesResources < ActiveRecord::Migration[7.0]
  def change
    create_join_table :contexts, :resources, table_name: :audiences_contexts_resources do |t|
      t.index %i[context_id resource_id]
    end
  end
end
