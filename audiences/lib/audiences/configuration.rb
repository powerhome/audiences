# frozen_string_literal: true

module Audiences
  include ActiveSupport::Configurable

  # Configuration options

  # Sync groups and users with TwoPercent
  config_accessor(:logger)

  # Sync groups and users with TwoPercent
  config_accessor(:observe_scim) { true }

  # Group types that can form an audience
  config_accessor :group_types do
    %w[Groups]
  end

  #
  # Authentication configuration. This defaults to true, meaning that the audiences
  # endpoints are open to the public.
  #
  # To authenticate requests, set this configuration to a lambda that will receive
  # the request and return true if the request is authenticated.
  #
  # Raising an exception will also prevent the execution of the request, but the
  # exception will not be caught and should be handled by the application middlewares.
  #
  # I.e.:
  #
  #   Audiences.configure do |config|
  #     config.authenticate = ->(*) { authenticate_request }
  #   end
  #
  # I.e:
  #
  #   Audiences.configure do |config|
  #     config.authenticate = ->(request) do
  #       request.env["warden"].authenticate!
  #     end
  #   end
  #
  config_accessor :authenticate do
    ->(*) { true }
  end

  #
  # Identity model representing a SCIM User in the current application. I.e.: "User"
  #
  config_accessor :identity_class

  #
  # The key attribute on `identity_class` matching with the SCIM User externalId.
  # This configuration defaults to `:id`
  #
  config_accessor(:identity_key) { :id }

  #
  # Notifications configurations.
  # Within this block, you should be able to easily register job classes to execute as
  # audiences are changed. Notice: this block is executed every time your app initializes
  # or reloads. This allows you to reference reloaded constants, like job names:
  #
  # I.e.:
  #
  #   Audiences.configure do |config|
  #     config.notifications do
  #       subscribe CallQueue, job: CallQueueMembersSyncJob
  #       subscribe ChatRoom, job: ChatRoomMembersSyncJob
  #     end
  #   end
  #
  # This block is executed
  # @see [Audiences::Notifications]
  def config.notifications(&block)
    Rails.application.config.to_prepare do
      Notifications.class_eval(&block)
    end
  end
end
