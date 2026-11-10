# frozen_string_literal: true

module Audiences
  class CriterionGroup < ApplicationRecord
    belongs_to :group
    belongs_to :criterion

    before_save { self.source_group_id ||= group.scim_id }
  end
end
