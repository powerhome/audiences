# frozen_string_literal: true

# Stands in for an adopter's own group model, the one `group_model_class`
# points at. Deliberately not an Audiences model.
class ExampleSourceGroup < ApplicationRecord
  has_many :example_source_memberships, dependent: :destroy
  has_many :example_source_users, through: :example_source_memberships
end
