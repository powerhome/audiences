# frozen_string_literal: true

module Audiences
  module Scim
    class UpsertGroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.create.#{group_type}"
        subscribe_to "two_percent.scim.replace.#{group_type}"
      end

      def process
        Audiences.logger.info "#{upsert_action} group #{new_display_name} (#{new_external_id})"

        group.update! external_id: new_external_id, display_name: new_display_name, active: new_active
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def upsert_action = group.persisted? ? "Updating" : "Creating"

      def new_external_id = event_payload.params["externalId"]

      def new_display_name = event_payload.params["displayName"]

      def new_active
        active = event_payload.params.dig("urn:ietf:params:scim:schemas:extension:authservice:2.0:Group", "active")
        active.nil? || active
      end

      def group
        @group ||= Audiences::Group.unscoped
                                   .where(resource_type: event_payload.resource,
                                          scim_id: event_payload.params["id"])
                                   .first_or_initialize
      end
    end
  end
end
