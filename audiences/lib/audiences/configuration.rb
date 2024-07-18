# frozen_string_literal: true

module Audiences
  include ActiveSupport::Configurable

  # Configuration options
  config_accessor :scim
  config_accessor :resources do
    { Users: Scim::Resource.new(type: :Users, attributes: "id,externalId,displayName,photos") }
  end

  def config.resource(type:, **kwargs)
    config.resources[type] = Scim::Resource.new(type: type, **kwargs)
  end

  def config.notifications(&block)
    Rails.application.config.to_prepare do
      Notifications.class_eval(&block)
    end
  end
end
