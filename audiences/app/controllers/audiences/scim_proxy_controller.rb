# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences::Scim.resources(
        type: params[:scim_path].to_sym,
        filter: params[:filter]
      )

      render json: resources
    end
  end
end
