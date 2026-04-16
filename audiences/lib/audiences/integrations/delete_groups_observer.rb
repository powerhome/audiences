# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for Group deletion domain events
    # Consumes domain events (NOT SCIM-specific)
    class DeleteGroupsObserver < ObserverBase
      subscribe_to "two_percent.domain.group.deleted"

      def process
        log_sync_operation("start")

        Audiences.logger.info "Deleting group #{scim_id} (#{resource_type})"

        # Find and destroy the group (cascade deletes group memberships)
        group = Audiences::Group.find_by(resource_type: resource_type, scim_id: scim_id)

        if group
          group.destroy!
          Audiences.logger.info "Group #{scim_id} deleted from Audiences cache"
        else
          Audiences.logger.warn "Group #{scim_id} not found in Audiences cache"
        end

        log_sync_operation("complete")
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def correlation_id
        event_payload.correlation_id
      end

      def scim_id
        event_payload.group_id
      end

      def resource_type
        event_payload.resource_type
      end

      def log_sync_operation(stage)
        log_data = {
          correlation_id: correlation_id,
          scim_id: scim_id,
          action: "delete",
          resource_type: resource_type,
          stage: stage,
          service: "audiences"
        }

        Audiences.logger.info(log_data.to_json)
      end
    end
  end
end
