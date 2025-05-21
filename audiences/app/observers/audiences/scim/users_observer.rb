# frozen_string_literal: true

module Audiences
  module Scim
    class UsersObserver < ObserverBase
      subscribe_to "two_percent.scim.create.Users"
      subscribe_to "two_percent.scim.replace.Users"

      def process
        external_user.update(user_id: event_payload.params["externalId"], data: event_payload.params)
      end

      def external_user
        @external_user ||= Audiences::ExternalUser.where(scim_id: event_payload.params["id"])
                                                  .first_or_initialize
      end
    end
  end
end
