# frozen_string_literal: true

module Audiences
  class ScimProxyController < ApplicationController
    # Reads resources through the configured source. The source is
    # swappable via Audiences.config.source (defaults to the legacy
    # source that reads Audiences' own projection), so the controller stays
    # agnostic to where the data comes from.
    def get
      render json: Audiences.source.fetch(
        resource_type: params[:scim_path],
        query: params[:query],
        start_index: params[:startIndex],
        count: params[:count]
      )
    end
  end
end
