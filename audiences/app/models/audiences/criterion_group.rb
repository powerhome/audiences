# frozen_string_literal: true

module Audiences
  class CriterionGroup < ApplicationRecord
    belongs_to :criterion
    belongs_to :group, class_name: "Audiences::Group", optional: true
    belongs_to :configured_group,
               class_name: Audiences.config.group_model_class.to_s,
               optional: true
  end
end
