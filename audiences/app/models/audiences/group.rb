# frozen_string_literal: true

module Audiences
  class Group < ApplicationRecord
    has_many :group_memberships, dependent: :destroy
    has_many :external_users, through: :group_memberships, dependent: :destroy

    validates :display_name, presence: true
    validates :external_id, presence: true
    validates :scim_id, presence: true

    scope :active, -> { where(active: true) }

    scope :search, ->(display_name) do
      where(arel_table[:display_name].matches("%#{display_name}%"))
    end

    scope :from_scim, ->(resource_type, *scim_json) do
      where(scim_id: scim_json.pluck("id"))
        .or(where(resource_type: resource_type, external_id: scim_json.pluck("externalId")))
    end

    def as_json(...)
      { "id" => scim_id, "externalId" => external_id, "displayName" => display_name }.as_json(...)
    end
  end
end
