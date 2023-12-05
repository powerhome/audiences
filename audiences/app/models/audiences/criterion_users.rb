# frozen_string_literal: true

module Audiences
  # @private
  class CriterionUsers
    include Enumerable

    def initialize(groups)
      @groups = groups
    end

    def each
      @groups.values
             .map { |groups| list_from_groups(groups.pluck("id")) }
             .reduce(&:&)
             &.each do |user|
        yield ExternalUser.for(user)
      end
    end

  private

    def list_from_groups(group_ids)
      filter = group_ids.map { "groups.value eq #{_1}" }.join(" OR ")
      Audiences::Scim.resources(type: :Users, filter: filter)
                     .all.to_a
    end
  end
end
