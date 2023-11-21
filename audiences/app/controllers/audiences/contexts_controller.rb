# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences.load(params.require(:key))
    end

    def update
      render_context Audiences.update(params.require(:key), **context_params)
    end

    def users
      context = Audiences.load(params.require(:key))

      render json: context.users
    end

  private

    def render_context(context)
      render json: context.as_json(
        only: %i[match_all extra_users],
        methods: %i[count],
        include: { criteria: { only: %i[groups], methods: %i[count] } }
      )
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
