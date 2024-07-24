# frozen_string_literal: true

class ExampleOwner < ApplicationRecord
  has_many :memberships, class_name: "ExampleMembership",
                         foreign_key: :owner_id,
                         dependent: :delete_all
  has_audience :members
end
