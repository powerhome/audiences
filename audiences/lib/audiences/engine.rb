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
        Audiences::Scim::UpsertUsersObserver.start
        Audiences::Scim::UpsertGroupsObserver.start
        Audiences::Scim::PatchGroupsObserver.start
        Audiences::Scim::PatchUsersObserver.start
      end
    end
  end
end
