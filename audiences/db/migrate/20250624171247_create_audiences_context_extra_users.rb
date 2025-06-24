# frozen_string_literal: true

class CreateAudiencesContextExtraUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :audiences_context_extra_users do |t|
      t.references :external_user, foreign_key: false
      t.references :context, foreign_key: false

      t.timestamps
    end
  end
end
