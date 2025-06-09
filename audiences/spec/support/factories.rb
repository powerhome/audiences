# frozen_string_literal: true

module Audiences
  module Test
    module Factories
      def next_scim_id
        @next_scim_id ||= 0
        @next_scim_id += 1
      end

      def create_group(scim_id: next_scim_id, **attrs)
        Audiences::Group.create!(scim_id: scim_id, display_name: "Group #{scim_id}",
                                 external_id: scim_id, resource_type: "Groups", **attrs)
      end

      def create_user(scim_id: next_scim_id, **attrs)
        data = { "id" => scim_id, "externalId" => scim_id, "displayName" => "User #{scim_id}" }
        Audiences::ExternalUser.create!(scim_id: scim_id, display_name: data["displayName"],
                                        user_id: data["externalId"], data: data, **attrs)
      end

      def create_users(number, **attrs)
        Array.new(number) { create_user(**attrs) }
      end
    end
  end
end
