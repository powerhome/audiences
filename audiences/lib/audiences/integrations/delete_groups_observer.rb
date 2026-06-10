# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for Group deletion domain events
    # Consumes domain events (NOT SCIM-specific)
    class DeleteGroupsObserver < ObserverBase
      subscribe_to "two_percent.domain.group.deleted"

      def process
        log_sync_operation("start")
        delete_group
        log_sync_operation("complete")
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def delete_group
        Audiences.logger.info "Deleting group #{scim_id} (#{resource_type})"

        group = find_group
        if group
          destroy_group(group)
        else
          log_group_not_found
        end
      end

      def find_group
        Audiences::ConfigurableAdapter.find_groups(resource_type, [{ "id" => scim_id }]).first
      end

      def destroy_group(group)
        group.destroy!
        Audiences.logger.info "Group #{scim_id} deleted from Audiences cache"
      end

      def log_group_not_found
        Audiences.logger.warn "Group #{scim_id} not found in Audiences cache"
      end

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
          service: "audiences",
        }

        Audiences.logger.info(log_data.to_json)
      end
    end
  end
end
