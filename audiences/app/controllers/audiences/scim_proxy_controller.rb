# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = Audiences.scim.query(params[:scim_path], filter: params[:filter])

      render json: resources
    end
  end
end
