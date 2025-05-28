# frozen_string_literal: true

module Audiences
  module Scim
    class PatchUsersObserver < ObserverBase
      subscribe_to "two_percent.scim.update.Users"

      def process
        attributes = FieldMapping.new("externalId" => :user_id,
                                      "displayName" => :display_name)
        data = ScimData.new

        patch_op = PatchOp.new(event_payload.params)
        patch_op.process user, attributes
        patch_op.process user, data

        user.save!
      end

    private

      def user
        @user ||= Audiences::ExternalUser.find_by(scim_id: event_payload.id)
      end
    end
  end
end
