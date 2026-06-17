# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for Group deletion domain events
    # Consumes domain events (NOT SCIM-specific)
    class DeleteGroupsObserver < ObserverBase
      subscribe_to "two_percent.domain.group.deleted"

      def process
        log_sync_operation(action: "delete", resource_type: resource_type, scim_id: scim_id) do
          delete_group
        end
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def scim_id
        event_payload.group_id
      end

      def resource_type
        event_payload.resource_type
      end

      def delete_group
        Audiences.logger.info "Deleting group #{scim_id} (#{resource_type})"

        group = Audiences::Group.find_by(resource_type: resource_type, scim_id: scim_id)

        if group
          group.destroy!
          Audiences.logger.info "Group #{scim_id} deleted from Audiences cache"
        else
          Audiences.logger.warn "Group #{scim_id} not found in Audiences cache"
        end
      end
    end
  end
end
