# frozen_string_literal: true

class AddSourceUserIdToAudiencesContextExtraUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :audiences_context_extra_users, :source_user_id, :string
    options = connection.adapter_name == "PostgreSQL" ? { algorithm: :concurrently } : {}
    add_index :audiences_context_extra_users, :source_user_id, **options
  end
end
