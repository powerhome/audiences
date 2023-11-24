# frozen_string_literal: true

module Audiences
  # @private
  class CriterionUsers
    include Enumerable

    def initialize(groups)
      @groups = groups
    end

    def each(...)
      @groups.values.map do |groups|
        filter = group_filter(groups.pluck("id"))
        Audiences::Scim.resources(type: :Users, filter: filter)
                       .all.to_a
      end
      .reduce(&:&)
      &.each(...)
    end

  private

    def group_filter(group_ids)
      group_ids.map { "groups.value eq #{_1}" }.join(" OR ")
    end
  end
end
