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
      app.config.assets.precompile += %w[audiences-rails.js] if app.config.respond_to?(:assets)
    end

    initializer "audiences.model" do
      if Audiences.config.identity_class
        ActiveSupport.on_load(:active_record) do
          include Audiences::Model
        end
      end
    end
  end
end
