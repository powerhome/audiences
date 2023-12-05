# frozen_string_literal: true

class RemoveSerializedUsersFromCriterion < ActiveRecord::Migration[6.0]
  def change
    remove_column :audiences_criterions, :users, :json
  end
end
