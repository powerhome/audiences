# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params[:key])
    end

    def update
      render_context Audiences.update(params[:key], **context_params.deep_symbolize_keys)
    end

  private

    def render_context(context)
      render json: context.as_json(only: %i[match_all], include: %i[resources], methods: %i[criteria])
    end

    def context_params
      params.permit(:match_all, resources: %i[resource_id resource_type display image_url]).to_h
    end
  end
end
