# frozen_string_literal: true

# Stands in for an adopter's own user model, the one `user_model_class`
# points at. Deliberately not an Audiences model.
class ExampleSourceUser < ApplicationRecord
  has_many :example_source_memberships, dependent: :destroy
  has_many :example_source_groups, through: :example_source_memberships

  scope :active, -> { all }
end
