# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for User deletion domain events
    # Consumes domain events (NOT SCIM-specific)
    class DeleteUsersObserver < ObserverBase
      subscribe_to "two_percent.domain.user.deleted"

      def process
        log_sync_operation(action: "delete", resource_type: "Users", scim_id: scim_id) do
          delete_user
        end
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def scim_id
        event_payload.user_id
      end

      def delete_user
        Audiences.logger.info "Deleting user #{scim_id}"

        user = Audiences::ExternalUser.find_by(scim_id: scim_id)

        if user
          user.destroy!
          Audiences.logger.info "User #{scim_id} deleted from Audiences cache"
        else
          Audiences.logger.warn "User #{scim_id} not found in Audiences cache"
        end
      end
    end
  end
end
