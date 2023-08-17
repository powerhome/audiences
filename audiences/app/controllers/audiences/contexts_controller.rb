# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params[:key])
    end

    def update
      render_context Audiences.update(params[:key], context_params)
    end

  private

    def render_context(context)
      render json: context.as_json(only: %w[match_all], methods: %w[criteria])
    end

    def context_params
      params.slice(:match_all).permit!
    end
  end
end
