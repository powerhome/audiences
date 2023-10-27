# frozen_string_literal: true

module Audiences
  # @private
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true

    store :criteria, accessors: %i[users groups], suffix: true

    # Finds or creates a context for the given owner
    #
    # @private
    # @return [Audiences::Context]
    def self.for(owner)
      where(owner: owner).first_or_create!
    end
  end
end
