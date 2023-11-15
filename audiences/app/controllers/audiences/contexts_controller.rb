# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params.require(:key))
    end

    def update
      render_context Audiences.update(params.require(:key), **context_params)
    end

  private

    def render_context(context)
      render json: context.as_json(only: %i[match_all extra_users], include: { criteria: { only: %i[groups] } })
    end

    def context_params
      params.permit(
        :match_all,
        criteria: [groups: {}],
        extra_users: [:id, :displayName, { photos: %i[type value] }]
      ).to_h.symbolize_keys
    end
  end
end
