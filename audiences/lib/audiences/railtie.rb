# frozen_string_literal: true

module Audiences
  class Railtie < Rails::Railtie
    initializer "audiences.editor_helper" do
      ActiveSupport.on_load(:action_view) do
        require "audiences/editor_helper"
        include Audiences::EditorHelper
      end
    end

    initializer "audiences.logger" do
      Audiences.config.logger ||= Rails.logger.tagged("Audiences")
    end
  end
end
