# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Audiences
  class Scim
    def initialize(uri:, headers: {})
      @uri = uri
      @headers = headers
    end

    def query(resource_type, filter:, wrapper: SafeObject)
      response = perform_request(path: resource_type, method: :Get, query: { filter: filter })

      response.fetch("Resources", response).map { wrapper.new(_1) }
    end

  private

    def perform_request(method:, path:, query: {})
      uri = URI.join(@uri, path.to_s)
      uri.query = URI.encode_www_form(query)
      request = ::Net::HTTP.const_get(method).new(uri, @headers)

      http = ::Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      response = http.request(request)

      JSON.parse(response.body)
    end
  end
end
