# frozen_string_literal: true

class ConfiguredUserGroup < ApplicationRecord
  belongs_to :configured_user
  belongs_to :group, class_name: "ConfiguredGroup"
end
