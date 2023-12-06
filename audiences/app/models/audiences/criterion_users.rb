# frozen_string_literal: true

module Audiences
  # @private
  class CriterionUsers
    include Enumerable

    def initialize(groups)
      @groups = groups
    end

    def each(...)
      @groups.values
             .map { |groups| groups_users(groups.pluck("id")) }
             .reduce(&:&)
             &.each(...)
    end

  private

    def groups_users(group_ids)
      filter = group_ids.map { "groups.value eq #{_1}" }.join(" OR ")
      Audiences::Scim.resources(type: :Users, filter: filter, wrapper: ExternalUser)
                     .all.to_a
    end
  end
end
