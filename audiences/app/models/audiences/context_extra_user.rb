# frozen_string_literal: true

module Audiences
  class ContextExtraUser < ApplicationRecord
    belongs_to :context
    belongs_to :external_user, optional: true
    belongs_to :configured_user, class_name: "ConfiguredUser", optional: true
  end
end
