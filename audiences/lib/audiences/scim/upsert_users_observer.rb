# frozen_string_literal: true

module Audiences
  module Scim
    class UpsertUsersObserver < ObserverBase
      subscribe_to "two_percent.scim.create.Users"
      subscribe_to "two_percent.scim.replace.Users"

      def process
        external_user.update(
          user_id: event_payload.params["externalId"],
          display_name: event_payload.params["displayName"],
          picture_urls: event_payload.params["photos"]&.pluck("value"),
          data: event_payload.params,
          groups: new_groups
        )
      end

    private

      def external_user
        @external_user ||= Audiences::ExternalUser.where(scim_id: event_payload.params["id"])
                                                  .first_or_initialize
      end

      def new_groups
        event_payload.params.fetch("groups", []).filter_map do |group|
          Audiences::Group.find_by(scim_id: group["value"])
        end
      end
    end
  end
end
