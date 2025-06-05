# frozen_string_literal: true

class CreateAudiencesGroupMemberships < ActiveRecord::Migration[6.1]
  def change
    create_table :audiences_group_memberships do |t|
      t.belongs_to :external_user, null: false, foreign_key: false, table: :audiences_external_users
      t.belongs_to :group, null: false, foreign_key: false, table: :audiences_external_users

      t.timestamps
    end
  end
end
