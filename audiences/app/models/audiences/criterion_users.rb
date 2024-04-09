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
      users = Audiences::Scim.resources(type: :Users, filter: filter)
      ExternalUser.wrap(users.all)
    end
  end
end
