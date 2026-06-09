# frozen_string_literal: true

module Audiences
  class ContextExtraUser < ApplicationRecord
    belongs_to :context
    belongs_to :external_user, optional: true
    # rubocop:disable Rails/ReflectionClassName - intentionally dynamic for adapter pattern
    belongs_to :configured_user,
               class_name: Audiences.config.user_model_class,
               optional: true
    # rubocop:enable Rails/ReflectionClassName
  end
end
