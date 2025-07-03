# frozen_string_literal: true

module Audiences
  module Test
    module Factories
      def next_scim_id
        @next_scim_id ||= 0
        @next_scim_id += 1
      end

      def create_group(scim_id: next_scim_id, resource_type: "Groups", **attrs)
        Audiences::Group.create!(scim_id: scim_id, display_name: "#{resource_type} #{scim_id}",
                                 external_id: scim_id, resource_type: resource_type, **attrs)
      end

      def create_user(scim_id: next_scim_id, user_id: scim_id, **attrs)
        data = { "id" => scim_id, "externalId" => user_id, "displayName" => "User #{scim_id}" }
        Audiences::ExternalUser.create!(scim_id: scim_id, display_name: data["displayName"],
                                        user_id: user_id, data: data, **attrs)
      end

      def create_example_owner
        ExampleOwner.create
      end

      def create_context(owner: create_example_owner, **attrs)
        owner.members_context.tap do |context|
          context.update!(attrs)
        end
      end

      def create_criterion(context: create_context, **attrs)
        context.criteria.create(**attrs)
      end

      def create_users(number, **attrs)
        Array.new(number) { create_user(**attrs) }
      end

      def create_groups(number, **attrs)
        Array.new(number) { create_group(**attrs) }
      end
    end
  end
end
