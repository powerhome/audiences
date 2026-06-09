# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for User deletion domain events
    # Consumes domain events (NOT SCIM-specific)
    class DeleteUsersObserver < ObserverBase
      subscribe_to "two_percent.domain.user.deleted"

      def process
        log_sync_operation("start")
        delete_user
        log_sync_operation("complete")
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def delete_user
        Audiences.logger.info "Deleting user #{scim_id}"

        user = find_user
        if user
          destroy_user(user)
        else
          log_user_not_found
        end
      end

      def find_user
        Audiences::ExternalUser.find_by(scim_id: scim_id)
      end

      def destroy_user(user)
        user.destroy!
        Audiences.logger.info "User #{scim_id} deleted from Audiences cache"
      end

      def log_user_not_found
        Audiences.logger.warn "User #{scim_id} not found in Audiences cache"
      end

      def correlation_id
        event_payload.correlation_id
      end

      def scim_id
        event_payload.user_id
      end

      def log_sync_operation(stage)
        log_data = {
          correlation_id: correlation_id,
          scim_id: scim_id,
          action: "delete",
          resource_type: "Users",
          stage: stage,
          service: "audiences",
        }

        Audiences.logger.info(log_data.to_json)
      end
    end
  end
end
