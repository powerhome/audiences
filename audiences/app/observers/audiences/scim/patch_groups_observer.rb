# frozen_string_literal: true

module Audiences
  module Scim
    class PatchGroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.update.#{group_type}"
      end

      def process
        patch_op = PatchOp.new(event_payload.params)
        attributes = FieldMapping.new("displayName" => :display_name,
                                      "externalId" => :external_id,
                                      "members" => {
                                        to: :external_users,
                                        find: ->(value) { ExternalUser.find_by(scim_id: value) },
                                      })

        patch_op.process(group, attributes)
        group.save!
      end

    private

      def group
        @group ||= Audiences::Group.find_by(resource_type: event_payload.resource,
                                            scim_id: event_payload.id)
      end
    end
  end
end
