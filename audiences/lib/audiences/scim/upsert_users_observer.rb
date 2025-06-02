# frozen_string_literal: true

module Audiences
  module Scim
    class UpsertUsersObserver < ObserverBase
      subscribe_to "two_percent.scim.create.Users"
      subscribe_to "two_percent.scim.replace.Users"

      def process
        Audiences.logger.info "#{upsert_action} group #{new_display_name} (#{scim_id})"

        external_user.update! user_id: new_external_id, display_name: new_display_name,
                              picture_urls: new_picture_urls, data: event_payload.params,
                              groups: new_groups
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def scim_id = event_payload.params["id"]

      def external_user
        @external_user ||= Audiences::ExternalUser.where(scim_id: scim_id).first_or_initialize
      end

      def upsert_action = external_user.persisted? ? "Updating" : "Creating"

      def new_display_name = event_payload.params["displayName"]

      def new_external_id = event_payload.params["externalId"]

      def new_picture_urls = event_payload.params["photos"]&.pluck("value")

      def new_groups
        event_payload.params.fetch("groups", []).filter_map do |group|
          Audiences::Group.find_by(scim_id: group["value"])
        end
      end
    end
  end
end
