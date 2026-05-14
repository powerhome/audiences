# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for Group creation/update domain events
    # Consumes domain events (NOT SCIM-specific)
    class UpsertGroupsObserver < ObserverBase
      subscribe_to "two_percent.domain.group.created"
      subscribe_to "two_percent.domain.group.updated"

      def process
        log_sync_operation("start")

        Audiences.logger.info "#{upsert_action} group #{group_attrs[:display_name]} (#{group_attrs[:external_id]})"

        group.update!(
          external_id: group_attrs[:external_id],
          display_name: group_attrs[:display_name],
          active: group_attrs.fetch(:active, true)
        )

        # Sync members if included in the event (from TwoPercent domain events)
        sync_members if group_attrs[:members].present?

        log_sync_operation("complete")
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def group_attrs
        @group_attrs ||= event_payload.group_attributes.with_indifferent_access
      end

      def correlation_id
        event_payload.correlation_id
      end

      def scim_id
        group_attrs[:scim_id]
      end

      def resource_type
        event_payload.resource_type
      end

      def upsert_action
        group.persisted? ? "Updating" : "Creating"
      end

      def group
        @group ||= Audiences::Group.where(
          resource_type: resource_type,
          scim_id: scim_id
        ).first_or_initialize
      end

      def sync_members
        member_scim_ids = group_attrs[:members].map { |m| m[:scim_id] || m['scim_id'] }.compact
        users = Audiences::ExternalUser.where(scim_id: member_scim_ids).to_a
        group.external_users = users
        group.save!
      end

      def log_sync_operation(stage)
        log_data = {
          correlation_id: correlation_id,
          scim_id: scim_id,
          action: upsert_action.downcase,
          resource_type: resource_type,
          stage: stage,
          service: "audiences"
        }

        Audiences.logger.info(log_data.to_json)
      end
    end
  end
end
