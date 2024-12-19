# frozen_string_literal: true

module Audiences
  class UsersSearch
    DEFAULT_LIMIT = 20

    def initialize(query:, limit: nil, offset: 0, scope: ExternalUser)
      @scope = scope
      @query = query
      @limit = limit || DEFAULT_LIMIT
      @offset = offset
    end

    def as_json(*)
      {
        users: users.as_json(*),
        count: count,
      }
    end

    delegate :count, to: :result

    def users
      @users ||= result.limit(@limit).offset(@offset)
    end

  private

    def result
      @result ||= @scope.where("#{data_attribute_query} LIKE ?", "%#{@query}%")
    end

    def data_attribute_query
      case @scope.connection.adapter_name
      when "PostgreSQL" then "CAST(data AS TEXT)"
      else "CAST(data AS CHAR)"
      end
    end
  end
end
