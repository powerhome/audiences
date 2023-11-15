# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params[:key])
    end

    def update
      render_context Audiences.update(params[:key], context_params.to_h)
    end

  private

    def render_context(context)
      render json: context.as_json(only: %i[match_all extra_users criteria])
    end

    def context_params
      params.permit(
        :match_all,
        criteria: {},
        extra_users: [:id, :displayName, { photos: %i[type value] }]
      )
    end
  end
end
