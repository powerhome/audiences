# frozen_string_literal: true

module Audiences
  module Sources
    # Default source.
    #
    # Reads Audiences' own projection (ExternalUser / Group / GroupMembership),
    # preserving the exact scoping, search, pagination and matching behavior the
    # gem has always had. Records are returned as they are stored; #present turns
    # them into the client-facing contract.
    class Legacy
      def fetch(resource_type:, query:, start_index:, count:)
        scope(resource_type)
          .search(query)
          .offset(start_index)
          .limit(count)
      end

      # @return [Enumerable<Group>] the groups of a criterion
      def groups_of(criterion)
        criterion.groups
      end

      # @param groups [Enumerable<Group>] a user must belong to at least one group
      #   of each resource type among these
      # @return [ActiveRecord::Relation<ExternalUser>] without the default users scope
      def users_matching(groups:)
        # Load the groups once: checking emptiness and loading separately lets a
        # concurrent criteria update empty the groups in between, and reducing
        # over no groups would match every user.
        groups = groups.to_a
        return ExternalUser.none if groups.empty?

        groups.group_by(&:resource_type)
              .values
              .reduce(ExternalUser.all) do |users, of_type|
          users.members_of(of_type)
        end
      end

      # @return [ActiveRecord::Relation<ExternalUser>] every user
      def all_users
        ExternalUser.all
      end

      # @return [ActiveRecord::Relation<ExternalUser>] the context's extra users,
      #   inactive ones included
      def extra_users_of(context)
        ExternalUser.where(id: context.context_extra_users.select(:external_user_id))
      end

      # @param records [ActiveRecord::Relation, Array] users or groups
      # @return [Array<Hash>] the records in the client-facing contract
      def present(records)
        records.map(&:as_json)
      end

      # @return [ActiveRecord::Relation<ExternalUser>] the users whose data match the query
      def search_users(users, query)
        users.where(data_search_sql(users), "%#{query}%")
      end

      # @return [Array<String, nil>] the identity key of each user, in the relation's order
      def identity_keys(users)
        users.pluck(:user_id)
      end

    private

      def data_search_sql(users)
        if users.connection.adapter_name == "PostgreSQL"
          "CAST(data AS TEXT) LIKE ?"
        else
          "CAST(data AS CHAR) LIKE ?"
        end
      end

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
