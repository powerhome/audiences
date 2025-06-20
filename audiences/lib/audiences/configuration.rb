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

  # Defines a default scope for users, so the users that are part of an audience can
  # be filtered (i.e.: only active, only users in a specific group, etc)
  #
  # By default, only active users are listed.
  #
  # I.e.:
  #
  #   # Allowing inactive users
  #   Audiences.configure do |config|
  #     config.default_users_scope = -> { all }
  #   end
  #
  #   # Accepting only users in certain groups
  #   Audiences.configure do |config|
  #     config.default_users_scope = -> { includes(:groups).merge(Audiences::Group.where(scim_id: ALLOWED_GROUPS)) }
  #   end
  #
  # This configuration defaults to `-> { where(active: true) }`
  #
  config_accessor :default_users_scope do
    ->(*) { where(active: true) }
  end

  # Defines a default scope for groups, so the groups that are part of an audience can
  # be filtered (i.e.: only active, only specific groups, etc)
  #
  # By default, only active groups are listed.
  #
  # I.e.:
  #
  #   # Allowing inactive groups
  #   Audiences.configure do |config|
  #     config.default_groups_scope = -> { all }
  #   end
  #
  #   # Accepting only groups in certain groups
  #   Audiences.configure do |config|
  #     config.default_groups_scope = -> { where(scim_id: ALLOWED_GROUPS) }
  #   end
  #
  # This configuration defaults to `-> { where(active: true) }`
  #
  config_accessor :default_groups_scope do
    ->(*) { where(active: true) }
  end

  # These are the user attributes that will be exposed in the audiences endpoints.
  # They're required by the UI to display the user information.
  #
  config_accessor :exposed_user_attributes do
    %w[id externalId displayName photos]
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
    ->(*) do
      Audiences.logger.warn(<<~MESSAGE)
        Audiences authenticate is currently configured using a default and is blocking authenticaiton.

        To make this wraning go away provide a configuration for `Audiences.config.authenticate`.

        The value should:
          1. Be callable like a Proc.
          2. Return true when the request is permitted.
          3. Return false when the request is not permitted.
      MESSAGE

      false
    end
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
  # SCIM service configurations. This should be a Hash containint, at least, the URI.
  #
  # I.e.:
  #
  #   Audiences.configure do |config|
  #     config.scim = { uri: "http://localhost/api/scim" }
  #   end
  #
  # It can also contain HTTP headers, such as "Authorization":
  #
  # I.e.:
  #
  #   Audiences.configure do |config|
  #     config.scim = {
  #       uri: "http://localhost/api/scim",
  #       headers: { "Authorization" => "Bearer auth-token" }
  #     }
  #   end
  #
  config_accessor :scim

  #
  # Resources defaults. Change this configuration via the `resource` helper.
  # This configuration lists the current Audiences accessible resource defaults,
  # and defaults to Users only. To add other resource types for criteria building.
  #
  # @see `resource`.
  #
  config_accessor :resources do
    { Users: Scim::Resource.new(type: :Users, attributes: ["active", { "photos" => %w[type value] }],
                                filter: "active eq true") }
  end

  #
  # Configures a resource default.
  #
  # @param type [Symbol] the resource type in plural, as in scim (i.e.: :Users)
  # @param attributes [String] the list of attributes to fetch for the resource (i.e.: "id,externalId,displayName")
  # @see [Audiences::Scim::Resource]
  def config.resource(type, **kwargs)
    resources[type] = Scim::Resource.new(type: type, **kwargs)
  end

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
