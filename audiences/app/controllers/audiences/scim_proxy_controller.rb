# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    def get
      resources = scope.search(params[:query])
                       .offset(params[:startIndex])
                       .limit(params[:count])

      render json: resources
    end

  private

    def scope
      if params[:scim_path].eql?("Users")
        Audiences::ExternalUser.instance_exec(&Audiences.default_users_scope)
      else
        Audiences::Group.where(resource_type: params[:scim_path])
                        .instance_exec(&Audiences.default_groups_scope)
      end
    end
  end
end
