# frozen_string_literal: true

module Audiences
  # @private
  class ContextExtraResource < ApplicationRecord
    belongs_to :context
    belongs_to :resource
  end
end
