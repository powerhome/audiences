# frozen_string_literal: true

module Audiences
  class ContextExtraUser < ApplicationRecord
    belongs_to :context
    belongs_to :external_user

    if Audiences.config.user_model_class
      belongs_to :configured_user, class_name: Audiences.config.user_model_class, # rubocop:disable Rails/ReflectionClassName
                                   optional: true,
                                   inverse_of: false
    end
  end
end
