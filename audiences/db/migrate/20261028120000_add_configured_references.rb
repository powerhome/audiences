# frozen_string_literal: true

class AddConfiguredReferences < ActiveRecord::Migration[6.1]
  def change
    add_reference :audiences_criterion_groups, :configured_group, foreign_key: false
    add_reference :audiences_context_extra_users, :configured_user, foreign_key: false
  end
end
