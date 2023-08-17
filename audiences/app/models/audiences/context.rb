# frozen_string_literal: true

module Audiences
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true

    # Finds or creates a context for the given owner
    #
    # @private
    # @return [Audiences::Context]
    def self.for(owner)
      where(owner: owner).first_or_create!
    end

    def criteria
      []
    end
  end
end
