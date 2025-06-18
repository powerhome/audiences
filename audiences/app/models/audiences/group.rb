# frozen_string_literal: true

module Audiences
  class Group < ApplicationRecord
    default_scope Audiences.default_groups_scope

    has_many :group_memberships, dependent: :destroy
    has_many :external_users, through: :group_memberships

    validates :display_name, presence: true
    validates :external_id, presence: true
    validates :scim_id, presence: true
  end
end
