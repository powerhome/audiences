# frozen_string_literal: true

# Test event classes that mimic TwoPercent domain events for testing
# Audiences observers without requiring the TwoPercent gem

module TestDomainEvents
  class ApplicationEvent < AetherObservatory::EventBase
    event_prefix "two_percent.domain"
  end

  class UserCreated < ApplicationEvent
    event_name "user.created"

    attribute :user_attributes
    attribute :correlation_id
  end

  class UserUpdated < ApplicationEvent
    event_name "user.updated"

    attribute :user_attributes
    attribute :correlation_id
  end

  class GroupCreated < ApplicationEvent
    event_name "group.created"

    attribute :group_attributes
    attribute :resource_type
    attribute :correlation_id
  end

  class GroupUpdated < ApplicationEvent
    event_name "group.updated"

    attribute :group_attributes
    attribute :resource_type
    attribute :correlation_id
  end
end
