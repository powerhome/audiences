# frozen_string_literal: true

module Audiences
  module Scim
    class PatchUsersObserver < ObserverBase
      subscribe_to "two_percent.scim.update.Users"

      def process
        Audiences.logger.info "Patching user #{user.display_name} (#{user.scim_id})"

        process_attributes!
        process_data!

        user.save!
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def patch_op = PatchOp.new(event_payload.params)

      def process_data! = patch_op.process(user, ScimData.new)

      def process_attributes!
        patch_op.process user, FieldMapping.new("externalId" => :user_id,
                                                "displayName" => :display_name,
                                                "active" => :active,
                                                "photos" => { to: :picture_urls, find: :itself })
      end

      def user
        @user ||= Audiences::ExternalUser.find_by!(scim_id: event_payload.id)
      end
    end
  end
end
