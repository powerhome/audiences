# frozen_string_literal: true

module Audiences
  class CriterionGroup < ApplicationRecord
    belongs_to :group
    belongs_to :criterion

    if Audiences.config.group_model_class
      belongs_to :configured_group, class_name: Audiences.config.group_model_class, # rubocop:disable Rails/ReflectionClassName
                                    optional: true,
                                    inverse_of: false
    end
  end
end
