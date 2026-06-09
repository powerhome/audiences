# frozen_string_literal: true

require "audiences"

module Audiences
  # Audiences Engine
  #
  # i.e.: `mount Audiences::Engine`
  #
  class Engine < ::Rails::Engine
    isolate_namespace Audiences

    initializer "audiences.editor_helper" do |app|
      app.config.assets.precompile += %w[audiences-ujs.js] if app.config.respond_to?(:assets)

      ActiveSupport.on_load(:action_view) do
        require "audiences/editor_helper"
        include Audiences::EditorHelper
      end
    end

    initializer "audiences.logger" do
      Audiences.config.logger ||= Rails.logger.tagged("Audiences")
    end

    initializer "audiences.model" do
      if Audiences.config.identity_class
        ActiveSupport.on_load(:active_record) do
          include Audiences::Model
        end
      end
    end

    initializer "audiences.observers" do
      if Audiences.config.observe_scim
        # Domain event observers (provider-agnostic)
        Audiences::Integrations::DeleteUsersObserver.start
        Audiences::Integrations::DeleteGroupsObserver.start
      end
    end

    initializer "audiences.validate_configuration", after: :load_config_initializers do
      config.after_initialize do
        Audiences.config.validate_adapter_configuration!
      end
    end
  end
end
