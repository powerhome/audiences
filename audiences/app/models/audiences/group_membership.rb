# frozen_string_literal: true

module Audiences
  class GroupMembership < ApplicationRecord
    belongs_to :external_user
    belongs_to :group
  end
end
