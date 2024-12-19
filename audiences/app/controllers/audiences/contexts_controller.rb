# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render_context Audiences::Context.load(params.require(:key))
    end

    def update
      render_context Audiences.update(params.require(:key), **context_params)
    end

    def users
      users = (current_criterion || current_context).users
      search = UsersSearch.new(scope: users,
                               query: params[:search],
                               limit: params[:limit],
                               offset: params[:offset])

      render json: search, only: Audiences.exposed_user_attributes
    end

  private

    def current_context
      @current_context ||= Audiences::Context.load(params.require(:key))
    end

    def current_criterion
      return unless params[:criterion_id]

      @current_criterion ||= current_context.criteria.find(params[:criterion_id])
    end

    def render_context(context)
      json_setting = {
        only: %i[match_all],
        methods: %i[count],
        include: { criteria: { only: %i[id groups], methods: %i[count] } }
      }
      extra_users = context.extra_users.as_json(only: Audiences.exposed_user_attributes)

      render json: { extra_users: extra_users, **context.as_json(json_setting) }
    end

    def context_params
      params.permit(
        :match_all,
        criteria: [groups: {}],
        extra_users: %i[externalId]
      ).to_h.symbolize_keys
    end
  end
end
