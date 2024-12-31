# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences::Scim.resource(params[:scim_path].to_sym)
                                 .query(
                                   filter: filter_param,
                                   startIndex: params[:startIndex], count: params[:count],
                                   attributes: Audiences.exposed_user_attributes.join(",")
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
