# frozen_string_literal: true

module Audiences
  include ActiveSupport::Configurable

  # Configuration options
  config_accessor :scim

  def config.notifications(&block)
    Rails.application.config.to_prepare do
      Notifications.class_eval(&block)
    end
  end
end
