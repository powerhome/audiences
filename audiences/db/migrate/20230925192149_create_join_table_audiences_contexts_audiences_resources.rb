# frozen_string_literal: true

class CreateJoinTableAudiencesContextsAudiencesResources < ActiveRecord::Migration[6.0]
  def change
    create_table :audiences_context_extra_resources do |t|
      t.references :context
      t.references :resource

      t.timestamps

      t.index %i[context_id resource_id], name: :idx_audiences_extra_resources_on_context_id_and_resource_id
    end
  end
end
