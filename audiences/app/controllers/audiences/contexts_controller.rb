# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params[:key])
    end

  private

    def render_context(context)
      render json: context.as_json(only: %w[match_all], methods: %w[criteria])
    end
  end
end
