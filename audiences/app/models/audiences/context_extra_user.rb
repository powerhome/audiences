# frozen_string_literal: true

module Audiences
  class ContextExtraUser < ApplicationRecord
    belongs_to :context
    belongs_to :external_user

    before_save { self.source_user_id ||= external_user.scim_id }
  end
end
