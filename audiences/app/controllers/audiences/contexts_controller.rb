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
      users = (current_criterion || current_context).users
                                                    .search(params[:search])
                                                    .limit(params[:limit] || 20)
                                                    .offset(params[:offset])

      render json: users
    end

  private

    def current_context
      @current_context ||= Audiences.load(params.require(:key))
    end

    def current_criterion
      return unless params[:criterion_id]

      @current_criterion ||= current_context.criteria.find(params[:criterion_id])
    end

    def render_context(context)
      render json: context.as_json(
        only: %i[match_all extra_users],
        methods: %i[count],
        include: { criteria: { only: %i[id groups], methods: %i[count] } }
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
