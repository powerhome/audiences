# frozen_string_literal: true

class ExampleSourceUser < ApplicationRecord
  has_many :example_source_memberships, dependent: :destroy
  has_many :example_source_groups, through: :example_source_memberships

  scope :active, -> { all }
end
