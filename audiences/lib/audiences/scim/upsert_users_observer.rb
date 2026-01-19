# frozen_string_literal: true

module Audiences
  module Scim
    class UpsertUsersObserver < ObserverBase
      subscribe_to "two_percent.scim.create.Users"
      subscribe_to "two_percent.scim.replace.Users"

      def process
        Audiences.logger.info "#{upsert_action} user #{event_payload.params['displayName']} (#{scim_id})"
        external_user.update! updated_attributes

        if external_user.missing_group_types.any?
          missing_types = external_user.missing_group_types.join(', ')
          Audiences.logger.warn "Provisioning event for user #{scim_id} with missing group types: #{missing_types}"
          return
        end

        Audiences::PersistedResourceEvent.create(resource_type: "Users", params: event_payload.params)
      end

    private

      def scim_id = event_payload.params["id"]

      def external_user
        @external_user ||= Audiences::ExternalUser.where(scim_id: scim_id).first_or_initialize
      end

      def upsert_action = external_user.persisted? ? "Updating" : "Creating"

      def updated_attributes
        {
          user_id: event_payload.params["externalId"],
          display_name: event_payload.params["displayName"],
          picture_urls: new_picture_urls,
          data: event_payload.params,
          groups: new_groups,
          active: event_payload.params.fetch("active", false),
        }
      end

      def new_picture_urls = event_payload.params["photos"]&.pluck("value")

      def new_groups
        event_payload.params.fetch("groups", []).filter_map do |group|
          Audiences::Group.find_by(scim_id: group["value"])
        end
      end
    end
  end
end
