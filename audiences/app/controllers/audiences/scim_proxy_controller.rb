# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences::Scim.resource(params[:scim_path].to_sym)
                                 .query(
                                   filter: "displayName co \"#{params[:filter]}\"",
                                   startIndex: params[:startIndex], count: params[:count],
                                   attributes: Audiences.exposed_user_attributes.join(",")
                                 )

      render json: resources, except: %w[schemas meta]
    end
  end
end
