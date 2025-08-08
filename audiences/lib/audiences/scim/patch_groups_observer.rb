# frozen_string_literal: true

module Audiences
  module Scim
    class PatchGroupsObserver < ObserverBase
      Audiences.config.group_types.each do |group_type|
        subscribe_to "two_percent.scim.update.#{group_type}"
      end

      def process
        Audiences.logger.info "Patching group #{group.display_name} (#{group.scim_id})"

        patch_op.process(group, attributes_mapping)

        group.save!

        propagate_changes_to_users!
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def patch_op = PatchOp.new(event_payload.params)

      def attributes_mapping
        FieldMapping.new("displayName" => :display_name,
                         "externalId" => :external_id,
                         "urn:ietf:params:scim:schemas:extension:authservice:2.0:Group:active" => :active,
                         "members" => { to: :external_users,
                                        find: ->(value) { ExternalUser.find_by(user_id: value) } })
      end

      def group
        @group ||= Group.find_by!(resource_type: event_payload.resource,
                                  scim_id: event_payload.id)
      end

      def propagate_changes_to_users!
        patch_op.operations.each do |operation|
          next unless operation.path == "members"

          ExternalUser.where(user_id: operation.value.pluck("value")).find_each do |user|
            TwoPercent::ReplaceEvent.create(resource: "Users", id: user.scim_id, params: user.as_scim)
          end
        end
      end
    end
  end
end
