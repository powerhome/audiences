# frozen_string_literal: true

module Audiences
  class Group < ApplicationRecord
    has_many :group_memberships, dependent: :destroy
    has_many :external_users, through: :group_memberships
  end
end
