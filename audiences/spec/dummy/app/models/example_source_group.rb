# frozen_string_literal: true

# Stands in for an adopter's own group model, the one `group_model_class`
# points at. Deliberately not an Audiences model.
class ExampleSourceGroup < ApplicationRecord
  has_many :example_source_memberships, dependent: :destroy
  has_many :example_source_users, through: :example_source_memberships

  def as_json(...)
    { "id" => id.to_s, "externalId" => id.to_s, "displayName" => display_name }.as_json(...)
  end
end
