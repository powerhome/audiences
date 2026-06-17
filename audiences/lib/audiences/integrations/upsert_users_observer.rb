# frozen_string_literal: true

module Audiences
  module Integrations
    # Observer for User creation/update domain events
    # Consumes domain events (NOT SCIM-specific)
    class UpsertUsersObserver < ObserverBase
      subscribe_to "two_percent.domain.user.created"
      subscribe_to "two_percent.domain.user.updated"

      def process
        log_sync_operation("start")
        upsert_user
        sync_groups
        log_sync_operation("complete")
      rescue => e
        Audiences.logger.error e
        raise
      end

    private

      def user_attrs
        @user_attrs ||= event_payload.user_attributes.with_indifferent_access
      end

      def scim_id
        user_attrs[:scim_id]
      end

      def correlation_id
        event_payload.correlation_id
      end

      def external_user
        @external_user ||= Audiences::ExternalUser.where(scim_id: scim_id).first_or_initialize
      end

      def upsert_action
        external_user.persisted? ? "Updating" : "Creating"
      end

      def updated_attributes
        {
          user_id: user_attrs[:external_id],
          display_name: user_attrs[:display_name],
          picture_urls: extract_picture_urls,
          data: build_data_hash,
          active: user_attrs.fetch(:active, false),
        }
      end

      def extract_picture_urls
        photos = user_attrs[:photos]
        return [] unless photos.is_a?(Array)

        photos.filter_map { |photo| photo["value"] || photo[:value] }
      end

      def find_associated_groups
        groups_data = user_attrs[:groups]
        return [] unless groups_data.is_a?(Array)

        group_scim_ids = groups_data.filter_map { |g| g[:scim_id] || g["scim_id"] }
        Audiences::Group.where(scim_id: group_scim_ids).to_a
      end

      def upsert_user
        Audiences.logger.info "#{upsert_action} user #{user_attrs[:display_name]} (#{scim_id})"
        external_user.update!(updated_attributes)
      end

      def sync_groups
        found_groups = find_associated_groups
        external_user.groups = found_groups
      end

      # Build minimal data hash for Audiences API responses
      # Group-derived attributes (title, department, territory, role) are built dynamically
      # in ExternalUser#groups_as_scim from GroupMembership associations
      def build_data_hash
        {
          "id" => scim_id,
          "externalId" => user_attrs[:external_id],
          "displayName" => user_attrs[:display_name],
          "userName" => user_attrs[:user_name],
          "photos" => user_attrs[:photos],
          "active" => user_attrs[:active],
        }.compact
      end

      def log_sync_operation(stage)
        log_data = {
          correlation_id: correlation_id,
          scim_id: scim_id,
          action: upsert_action.downcase,
          resource_type: "Users",
          stage: stage,
          service: "audiences",
        }

        Audiences.logger.info(log_data.to_json)
      end
    end
  end
end
