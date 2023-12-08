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
      Scim.resources(type: :Users, wrapper: ExternalUser)
          .all
    end

    def matching_users
      extras = ExternalUser.wrap(@context.extra_users)
      [*extras, *@context.criteria.flat_map(&:users)].uniq
    end
  end
end
