# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences::Scim.resource(params[:scim_path].to_sym)
                                 .query(filter: params[:filter], startIndex: params[:startIndex], count: params[:count])

      render json: resources, except: %w[schemas meta]
    end
  end
end
