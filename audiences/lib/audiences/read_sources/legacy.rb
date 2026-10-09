# frozen_string_literal: true

module Audiences
  module ReadSources
    # Default read source.
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
