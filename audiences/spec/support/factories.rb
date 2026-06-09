# frozen_string_literal: true

module Audiences
  module Test
    module Factories
      def next_scim_id
        @next_scim_id ||= 0
        @next_scim_id += 1
      end

      # Mode-aware factory - creates appropriate model based on configuration
      def create_group(external_id: next_scim_id, resource_type: "Groups", external_users: [], **attrs)
        if Audiences.config.use_configured_models
          create_configured_group(external_id: external_id, resource_type: resource_type,
                                  external_users: external_users, **attrs)
        else
          create_legacy_group(external_id: external_id, resource_type: resource_type, external_users: external_users,
                              **attrs)
        end
      end

      # Explicit factory for configured groups
      def create_configured_group(external_id: next_scim_id, resource_type: "Groups", external_users: [], **attrs)
        group = ConfiguredGroup.create!(
          external_id: external_id,
          display_name: "#{resource_type} #{external_id}",
          resource_type: resource_type,
          **attrs
        )

        # Create join records for user associations
        external_users.each do |user|
          ConfiguredUserGroup.create!(configured_user: user, group: group)
        end

        group
      end

      # Explicit factory for legacy groups
      def create_legacy_group(external_id: next_scim_id, resource_type: "Groups", _external_users: [], **attrs)
        # Extract scim_id if provided in attrs, otherwise use external_id
        scim_id = attrs.delete(:scim_id) || external_id

        Audiences::Group.create!(
          scim_id: scim_id,
          external_id: external_id,
          display_name: "#{resource_type} #{external_id}",
          resource_type: resource_type,
          **attrs
        )
      end

      # Mode-aware factory - creates appropriate model based on configuration
      def create_user(user_id: next_scim_id, groups: [], **attrs)
        if Audiences.config.use_configured_models
          create_configured_user(user_id: user_id, groups: groups, **attrs)
        else
          create_legacy_user(user_id: user_id, groups: groups, **attrs)
        end
      end

      # Explicit factory for configured users
      def create_configured_user(user_id: next_scim_id, groups: [], **attrs)
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

      # Explicit factory for legacy users
      def create_legacy_user(user_id: next_scim_id, _groups: [], **attrs)
        # Extract scim_id if provided in attrs, otherwise use user_id
        scim_id = attrs.delete(:scim_id) || user_id

        data = { "id" => scim_id, "externalId" => user_id, "displayName" => "User #{user_id}" }
        Audiences::ExternalUser.create!(
          scim_id: scim_id,
          user_id: user_id,
          display_name: "User #{user_id}",
          data: data,
          **attrs
        )
      end

      # Creates both ExternalUser and ConfiguredUser with matching user_id
      # Used for testing dual-write behavior
      def create_user_with_configured(user_id: next_scim_id, **attrs)
        # Always create ConfiguredUser explicitly (not mode-aware)
        configured_user = create_configured_user(user_id: user_id, **attrs)

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
        # Convert 'groups' to appropriate association based on mode
        if attrs[:groups]
          attrs = if Audiences.config.use_configured_models
                    attrs.merge(groups_configured: attrs.delete(:groups))
                  else
                    attrs.merge(groups_legacy: attrs.delete(:groups))
                  end
        end
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
