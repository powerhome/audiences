# frozen_string_literal: true

class ExampleSourceGroup < ApplicationRecord
  has_many :example_source_memberships, dependent: :destroy
  has_many :example_source_users, through: :example_source_memberships

  scope :active, -> { all }
end
