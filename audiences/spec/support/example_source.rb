# frozen_string_literal: true

module Audiences
  module Test
    # A source backed by the dummy app's own models rather than Audiences'
    # projection. Stands in for an adopter's adapter so specs can prove the
    # seam actually swaps.
    class ExampleSource
      def initialize
        @group_references = {}
        @group_external_references = {}
        @user_references = {}
        @user_external_references = {}
      end

      def register_group(group, id:, external_id:)
        @group_references[[group.resource_type, id.to_s]] = group.id
        @group_external_references[[group.resource_type, external_id.to_s]] = group.id
      end

      def register_user(user, id:, external_id:)
        @user_references[id.to_s] = user.id
        @user_external_references[external_id.to_s] = user.id
      end

      def fetch(resource_type:, query:, start_index:, count:)
        ExampleSourceGroup.where(resource_type: resource_type)
                          .where(ExampleSourceGroup.arel_table[:display_name].matches("%#{query}%"))
                          .offset(start_index)
                          .limit(count)
      end

      def all_users
        ExampleSourceUser.all
      end

      def identity_values_for(users:)
        values_by_user_id = @user_external_references.invert
        users.pluck(:id).map { |id| values_by_user_id[id] }
      end

      def search_users(scope:, query:)
        scope.where(ExampleSourceUser.arel_table[:display_name].matches("%#{query}%"))
      end

      def extra_users_of(context)
        ExampleSourceUser.where(id: context.context_extra_users.select(:configured_user_id))
      end

      def users_matching(groups:)
        return ExampleSourceUser.none if groups.empty?

        groups.group_by(&:resource_type)
              .values
              .reduce(ExampleSourceUser.all) { |users, of_type| users.where(id: member_ids_of(of_type)) }
      end

      def groups_of(criterion)
        criterion.criterion_groups.filter_map(&:configured_group)
      end

      def resolve_criterion_groups(resource_type:, references:)
        ids = references.flat_map do |reference|
          [
            @group_references[[resource_type, reference["id"].to_s]] || reference["id"],
            @group_external_references[[resource_type, reference["externalId"].to_s]],
          ]
        end.compact
        ExampleSourceGroup.where(resource_type: resource_type, id: ids)
      end

      def resolve_extra_users(references:)
        ids = references.flat_map do |reference|
          [
            @user_references[reference["id"].to_s] || reference["id"],
            @user_external_references[reference["externalId"].to_s],
          ]
        end.compact
        ExampleSourceUser.where(id: ids)
      end

    private

      def member_ids_of(groups)
        ExampleSourceMembership.where(example_source_group: groups).select(:example_source_user_id)
      end
    end

    # Consumer operations follow selection; picked-reference resolution does not.
    class ExampleSelector
      attr_accessor :use_configured
      attr_reader :configured

      def initialize
        @configured = ExampleSource.new
        @legacy = Sources::Legacy.new
      end

      delegate :fetch, :all_users, :groups_of, :users_matching, :extra_users_of, :search_users, to: :selected
      delegate :identity_values_for, to: :selected
      delegate :resolve_criterion_groups, :resolve_extra_users, to: :@configured

    private

      def selected
        use_configured ? @configured : @legacy
      end
    end
  end
end
