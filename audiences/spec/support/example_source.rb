# frozen_string_literal: true

module Audiences
  module Test
    # A source backed by the dummy app's own models rather than Audiences'
    # projection. Stands in for an adopter's adapter so specs can prove the
    # seam actually swaps.
    class ExampleSource
      def fetch(resource_type:, query:, start_index:, count:)
        ExampleSourceGroup.where(resource_type: resource_type)
                          .where(ExampleSourceGroup.arel_table[:display_name].matches("%#{query}%"))
                          .offset(start_index)
                          .limit(count)
      end

      def all_users
        ExampleSourceUser.all
      end

      def extra_users_of(context)
        ExampleSourceUser.where(id: context.context_extra_users.select(:configured_user_id))
      end

      def users_matching(groups:)
        return ExampleSourceUser.none if groups.empty?

        groups.group_by(&:resource_type)
              .values
              .reduce(ExampleSourceUser.all) { |users, of_type| users.merge(members_of(of_type)) }
      end

      def groups_of(criterion)
        criterion.criterion_groups.filter_map(&:configured_group)
      end

      def resolve_criterion_groups(resource_type:, references:)
        ExampleSourceGroup.where(resource_type: resource_type, id: references.pluck("id"))
      end

      def resolve_extra_users(references:)
        ExampleSourceUser.where(id: references.pluck("id"))
      end

    private

      def members_of(groups)
        ExampleSourceUser.where(
          id: ExampleSourceMembership.where(example_source_group: groups).select(:example_source_user_id)
        )
      end
    end
  end
end
