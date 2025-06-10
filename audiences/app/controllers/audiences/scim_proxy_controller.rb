# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      groups = scope.search(params[:query])
                    .offset(params[:startIndex])
                    .limit(params[:count])

      render json: groups
    end

  private

    def scope
      if params[:scim_path].eql?("Users")
        Audiences::ExternalUser
      else
        Audiences::Group.where(resource_type: params[:scim_path])
      end
    end
  end
end
