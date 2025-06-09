# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def users
      users = Audiences::ExternalUser.where('display_name LIKE "%?%"', params[:query])

      render json: users
    end

    def get
      resources = Audiences::Scim.resource(params[:scim_path].to_sym)
                                 .query(
                                   filter: filter_param,
                                   startIndex: params[:startIndex], count: params[:count],
                                   attributes: %w[id externalId displayName photos].join(",")
                                 )

      render json: resources, except: %w[schemas meta]
    end

  private

    def filter_param
      if params[:query]
        "displayName co \"#{params[:query]}\""
      else
        params[:filter]
      end
    end
  end
end
