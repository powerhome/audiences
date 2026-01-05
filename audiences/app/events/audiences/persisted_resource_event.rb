# frozen_string_literal: true

module Audiences
  class PersistedResourceEvent < ApplicationEvent
    event_name { "persisted.#{resource_type}" }

    attribute :params
    attribute :resource_type
  end
end

