# frozen_string_literal: true

class RemoveCriteriaFromAudiencesContext < ActiveRecord::Migration[6.0]
  def change
    remove_column :audiences_contexts, :criteria, :json
  end
end
