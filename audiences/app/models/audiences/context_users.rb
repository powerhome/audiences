# frozen_string_literal: true

module Audiences
  # @private
  class ContextUsers
    include Enumerable

    def initialize(context)
      @context = context
    end

    def each(...)
      if @context.match_all
        all_users.each(...)
      else
        matching_users.each(...)
      end
    end

  private

    def all_users
      Scim.resources(type: :Users)
          .all.map { ExternalUser.for(_1) }
    end

    def matching_users
      extras = @context.extra_users
                       &.map { ExternalUser.for(_1) }
      [*extras, *@context.criteria.flat_map(&:users)].uniq
    end
  end
end
