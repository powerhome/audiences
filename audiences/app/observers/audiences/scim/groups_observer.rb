# frozen_string_literal: true

module Audiences
  module Scim
    class GroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.create.#{group_type}"
        subscribe_to "two_percent.scim.replace.#{group_type}"
      end

      def process
        group.update(
          external_id: event_payload.params["externalId"],
          display_name: event_payload.params["displayName"],
          data: event_payload.params
        )
      end

      def group
        @group ||= Audiences::Group.where(resource_type: event_payload.resource,
                                          scim_id: event_payload.params["id"])
                                   .first_or_initialize
      end
    end
  end
end
