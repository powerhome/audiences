# frozen_string_literal: true

module Audiences
  class Membership < ApplicationRecord
    belongs_to :external_user
    belongs_to :group, polymorphic: true
  end
end
