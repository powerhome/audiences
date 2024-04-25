# frozen_string_literal: true

module Audiences
  # Handles notification of audience context changes. The notifications handled
  # by this module are related to the membership composition of a context.
  #
  # For instance, when a user leaves a group, the app will be notified of changes
  # to the members of that context so it can react to that. When the audience
  # configuration of a context changes, a notification will also be published
  # through `Audiences::Notifications`.
  #
  module Notifications
    mattr_reader :subscriptions, default: {}

  module_function

    # Subscribes to audience changes to a specific owner type, either with a
    # background job or a callable block
    #
    # @param owner_type [Class] the type of owners handled by the job or block
    # @param job [Class<ActiveJob::Base>] job that will respond to audience changes
    # @yield block that will handle the audience change if a job is not given
    #
    def subscribe(owner_type, job: nil, &cbk)
      subscriptions[owner_type] = job&.method(:perform_later) || cbk
    end

    # Notifies that a given audience context was changed
    #
    # @param context [Audiences::Context] updated context
    #
    def publish(context)
      subscriptions[context.owner.class]&.call(context)
    end
  end
end
