# frozen_string_literal: true

module Audiences
  module Sources
    # Default source.
    #
    # Reads Audiences' own projection (ExternalUser / Group), preserving the exact
    # scoping, search and pagination behavior the read endpoint has always had.
    # Records are returned as-is so the controller's `render json:` uses each
    # model's `as_json` to produce the client-facing contract.
    class Legacy
      def fetch(resource_type:, query:, start_index:, count:)
        scope(resource_type)
          .search(query)
          .offset(start_index)
          .limit(count)
      end

      # Reads the legacy `criterion_groups.group_id` reference. Phase 4 drops
      # that column along with this class.
      def groups_of(criterion)
        criterion.groups
      end

      def users_matching(groups:)
        return ExternalUser.none if groups.empty?

        groups.group_by(&:resource_type)
              .values
              .reduce(ExternalUser.all) { |users, of_type| users.members_of(of_type) }
      end

      def all_users
        ExternalUser.all
      end

      # Reads the legacy `context_extra_users.external_user_id` reference.
      # Phase 4 drops that column along with this class.
      def extra_users_of(context)
        ExternalUser.where(id: context.context_extra_users.select(:external_user_id))
      end

      def resolve_extra_users(references:)
        ExternalUser.from_scim(*references)
      end

      def resolve_criterion_groups(resource_type:, references:)
        Group.from_scim(resource_type, *references)
      end

    private

      def scope(resource_type)
        if resource_type == "Users"
          ExternalUser.instance_exec(&Audiences.default_users_scope)
        else
          Group.where(resource_type: resource_type).instance_exec(&Audiences.default_groups_scope)
        end
      end
    end
  end
end
