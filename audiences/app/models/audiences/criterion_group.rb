# frozen_string_literal: true

module Audiences
  class CriterionGroup < ApplicationRecord
    belongs_to :criterion
    belongs_to :group, class_name: "Audiences::Group", optional: true
    # rubocop:disable Rails/ReflectionClassName - intentionally dynamic for adapter pattern
    belongs_to :configured_group,
               class_name: Audiences.config.group_model_class,
               optional: true
    # rubocop:enable Rails/ReflectionClassName
  end
end
