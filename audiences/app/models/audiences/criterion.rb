# frozen_string_literal: true

module Audiences
  class Criterion < ApplicationRecord
    belongs_to :context, class_name: "Audiences::Context"

    def self.map(criteria)
      Array(criteria).map { new(_1) }
    end
  end
end
