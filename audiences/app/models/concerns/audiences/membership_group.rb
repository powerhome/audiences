# frozen_string_literal: true

module Audiences
  module MembershipGroup
    extend ActiveSupport::Concern

    included do
      has_many :memberships, as: :group, dependent: :delete_all
      has_many :users, through: :memberships, source: :external_user, dependent: :delete_all

      delegate :count, to: :users
    end
  end
end
