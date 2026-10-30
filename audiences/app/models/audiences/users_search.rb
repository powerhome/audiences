# frozen_string_literal: true

module Audiences
  class UsersSearch
    DEFAULT_LIMIT = 20

    def initialize(query:, limit: nil, offset: 0, scope: Audiences.source.all_users)
      @scope = scope
      @query = query
      @limit = limit || DEFAULT_LIMIT
      @offset = offset
    end

    def as_json(...)
      {
        users: users.as_json(...),
        count: count,
      }
    end

    delegate :count, to: :result

    def users
      @users ||= result.limit(@limit).offset(@offset)
    end

  private

    def result
      @result ||= Audiences.source.search_users(scope: @scope, query: @query)
    end
  end
end
