# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences::Scim.resource(params[:scim_path].to_sym)
                                 .query(filter: params[:filter])

      render json: resources
    end
  end
end
