# frozen_string_literal: true

require "audiences"

module Audiences
  # Audiences Engine
  #
  # i.e.: `mount Audiences::Engine`
  #
  class Engine < ::Rails::Engine
    isolate_namespace Audiences

    initializer "audiences.assets.precompile" do |app|
      app.config.assets.precompile += %w[audiences-ujs.js] if app.config.respond_to?(:assets)
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
