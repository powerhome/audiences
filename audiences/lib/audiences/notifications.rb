# frozen_string_literal: true

module Audiences
  # @private
  module Notifications
    mattr_reader :subscriptions, default: {}

  module_function

    def subscribe(owner_type, job: nil, &cbk)
      subscriptions[owner_type] = job&.method(:perform_later) || cbk
    end

    def publish(context)
      subscriptions[context.owner.class]&.call(context)
    end
  end
end
