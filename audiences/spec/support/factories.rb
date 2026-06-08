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

      def create_user(user_id: next_scim_id, groups: [], **attrs)
        user = ConfiguredUser.create!(
          user_id: user_id,
          display_name: "User #{user_id}",
          **attrs
        )
        
        groups.each do |group|
          ConfiguredUserGroup.create!(configured_user: user, group: group)
        end
        
        user
      end
      
      # Creates both ExternalUser and ConfiguredUser with matching user_id
      # Used for testing dual-write behavior
      def create_user_with_configured(user_id: next_scim_id, **attrs)
        # Create ConfiguredUser (primary model)
        configured_user = create_user(user_id: user_id, **attrs)
        
        # Create matching ExternalUser for dual-write testing
        data = { "id" => user_id, "externalId" => user_id, "displayName" => "User #{user_id}" }
        Audiences::ExternalUser.create!(
          scim_id: user_id,
          display_name: configured_user.display_name,
          user_id: user_id,
          data: data,
          active: configured_user.active
        )
        
        configured_user
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
