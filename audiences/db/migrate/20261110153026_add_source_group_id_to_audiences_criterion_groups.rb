# frozen_string_literal: true

class AddSourceGroupIdToAudiencesCriterionGroups < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :audiences_criterion_groups, :source_group_id, :string
    options = connection.adapter_name == "PostgreSQL" ? { algorithm: :concurrently } : {}
    add_index :audiences_criterion_groups, :source_group_id, **options
  end
end
