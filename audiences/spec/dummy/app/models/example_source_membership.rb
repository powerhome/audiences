# frozen_string_literal: true

class ExampleSourceMembership < ApplicationRecord
  belongs_to :example_source_user
  belongs_to :example_source_group
end
