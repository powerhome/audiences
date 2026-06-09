# frozen_string_literal: true

# Test model to represent a configured identity provider group model
class ConfiguredGroup < ApplicationRecord
  self.table_name = "configured_groups"

  has_many :configured_user_groups, dependent: :destroy
  has_many :users, through: :configured_user_groups, source: :configured_user, class_name: "ConfiguredUser"
end
