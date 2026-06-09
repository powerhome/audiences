# frozen_string_literal: true

# Test model to represent a configured identity provider model
class ConfiguredUser < ApplicationRecord
  self.table_name = "configured_users"

  has_many :configured_user_groups, dependent: :destroy
  has_many :groups, through: :configured_user_groups, source: :group, class_name: "ConfiguredGroup"

  scope :active, -> { where(active: true) }

  scope :members_of, ->(groups) do
    where(id: ConfiguredUserGroup.where(group: groups).select(:configured_user_id))
  end
end
