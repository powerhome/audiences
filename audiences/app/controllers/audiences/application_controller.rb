# frozen_string_literal: true

module Audiences
  class ApplicationController < ActionController::API
    before_action unless: :authenticate! do
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

  private

    def authenticate!
      instance_exec(request, &Audiences.config.authenticate)
    end
  end
end
