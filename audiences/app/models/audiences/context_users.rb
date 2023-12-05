# frozen_string_literal: true

module Audiences
  # @private
  class ContextUsers
    include Enumerable

    def initialize(context)
      @context = context
    end

    def each(&block)
      _matching_users.each(&block)
      @context.extra_users&.each do |data|
        yield ExternalUser.for(data)
      end
    end

  private

    def _matching_users
      if @context.match_all
        Scim.resources(type: :Users)
            .all.map { ExternalUser.for(_1) }
      else
        @context.criteria.flat_map(&:users).uniq
      end
    end
  end
end
