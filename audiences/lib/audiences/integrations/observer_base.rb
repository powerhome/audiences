# frozen_string_literal: true

module Audiences
  module Integrations
    class ObserverBase < AetherObservatory::ObserverBase
      # Logs the start and completion of a sync operation
      # Automatically logs "start" before yielding and "complete" in ensure block
      #
      # @param action [String] The action being performed (e.g., "create", "update", "delete")
      # @param resource_type [String] The type of resource (e.g., "Users", "Groups")
      # @param scim_id [String] The SCIM ID of the resource
      # @param correlation_id [String] The correlation ID from the event (defaults to event_payload.correlation_id)
      # @yield The block containing the sync operation
      def log_sync_operation(action:, resource_type:, scim_id:, correlation_id: event_payload.correlation_id)
        log_data = {
          correlation_id: correlation_id,
          scim_id: scim_id,
          action: action,
          resource_type: resource_type,
          service: "audiences",
        }

        Audiences.logger.info({ **log_data, stage: "start" }.to_json)
        yield
      ensure
        Audiences.logger.info({ **log_data, stage: "complete" }.to_json)
      end
    end
  end
end
