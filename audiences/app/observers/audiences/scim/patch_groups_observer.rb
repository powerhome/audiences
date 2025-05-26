# frozen_string_literal: true

module Audiences
  module Scim
    class PatchGroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.update.#{group_type}"
      end

      def process
        patch_operations.process!(
          group,
          "displayName" => :display_name,
          "externalId" => :external_id,
          "members" => {
            to: :external_users,
            find: ->(value) { ExternalUser.find_by(scim_id: value) },
          }
        )
      end

    private

      def group
        @group ||= Audiences::Group.find_by(scim_id: event_payload.id)
      end

      def patch_operations
        PatchOp.new(event_payload.params)
      end
    end
  end
end
