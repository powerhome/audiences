# frozen_string_literal: true

module Audiences
  # ConfigurableAdapter provides a flexible adapter pattern that allows
  # Audiences to work with any data source by configuring transformation
  # and scope procs in the initializer.
  #
  # This eliminates the need to modify source models and keeps all
  # integration logic in the consuming application's configuration.
  # rubocop:disable Metrics/ClassLength - central adapter handles all routing logic
  class ConfigurableAdapter
    def initialize(record)
      @record = record
      @hash = nil
    end

    # Transform record to hash format expected by Audiences
    # Uses configured transformation proc
    def to_audiences_hash
      @to_audiences_hash ||= Audiences.config.to_audiences_hash_proc.call(@record)
    end

    # Provide convenient access to hash attributes
    def id
      to_audiences_hash[:id]
    end

    def external_id
      to_audiences_hash[:external_id]
    end

    def display_name
      to_audiences_hash[:display_name]
    end

    def active
      to_audiences_hash[:active]
    end

    def user_id
      to_audiences_hash[:user_id] || to_audiences_hash[:external_id]
    end

    def data
      to_audiences_hash[:data] || {}
    end

    def groups
      to_audiences_hash[:groups] || []
    end

    # Enable comparison based on underlying record ID
    def ==(other)
      if other.is_a?(ConfigurableAdapter)
        id == other.id
      else
        # Compare with underlying record type (for tests)
        @record == other
      end
    end

    alias eql? ==

    delegate :hash, to: :id

    class << self
      # Returns the configured model class
      # Supports both Class objects and String class names (constantized lazily)
      def model_class
        klass = Audiences.config.user_model_class
        klass.is_a?(String) ? klass.constantize : klass
      end

      # Returns the base user model class based on mode
      # Legacy mode: ExternalUser, Configured mode: configured user model
      def user_model_for_queries
        if Audiences.config.use_configured_models
          model_class
        else
          Audiences::ExternalUser
        end
      end

      # Returns relation with active users eligible for audiences
      # Routes to appropriate model based on mode
      def active_audiences_users
        if Audiences.config.use_configured_models
          apply_scope(Audiences.config.active_users_scope_proc)
        else
          # Legacy mode: use ExternalUser.active
          Audiences::ExternalUser.active
        end
      end

      # Returns relation filtered by group membership
      # Routes to appropriate model and scope based on mode
      def audiences_members_of(groups)
        if Audiences.config.use_configured_models
          apply_scope(Audiences.config.members_of_scope_proc, groups)
        else
          # Legacy mode: use ExternalUser.members_of
          Audiences::ExternalUser.members_of(groups)
        end
      end

      # Find users by their IDs from the source system
      # Routes to appropriate model based on mode
      # @param ids [Array<String>] Array of user IDs from source system
      # @return [ActiveRecord::Relation] Users matching the given IDs
      def audiences_find_by_ids(ids)
        return user_model_for_queries.none if ids.blank?

        if Audiences.config.use_configured_models
          apply_scope(Audiences.config.find_by_ids_proc, ids)
        else
          # Legacy mode: use ExternalUser with adapter's ID extraction
          Audiences::ExternalUser.where(id: ids)
        end
      end

      # Find groups from criterion data
      # Routes to configured model or legacy groups based on use_configured_models setting
      # @param resource_type [String] The resource type (e.g., "Departments", "Territories")
      # @param group_data [Array<Hash>] Array of group hashes with "id" or "externalId" keys
      # @return [Array] Array of group records (configured model or Audiences::Group)
      def find_groups(resource_type, group_data)
        if Audiences.config.use_configured_models && Audiences.config.find_groups_proc
          # Configured mode: use find_groups_proc to query configured model
          Audiences.config.find_groups_proc.call(resource_type, group_data).to_a
        else
          # Legacy mode: use built-in SCIM groups
          Audiences::Group.from_scim(resource_type, *group_data).to_a
        end
      end

      # Assign users to a context's extra_users
      # Handles routing to appropriate associations based on mode and user type
      # @param context [Audiences::Context] The context to assign users to
      # @param users [Array] Array of user records (ExternalUser or configured model)
      def assign_users_to_context(context, users)
        if users.blank?
          clear_extra_users(context)
          return
        end

        ensure_context_persisted(context)
        write_users_by_mode(context, users)
      end

      # Get users from a context's extra_users
      # Routes to appropriate association based on mode
      # @param context [Audiences::Context] The context to get users from
      # @return [ActiveRecord::Relation] User records from appropriate association
      def get_users_from_context(context)
        if Audiences.config.use_configured_models
          context.extra_users_configured
        else
          context.extra_users_legacy
        end
      end

      # Support ActiveRecord query methods by delegating to appropriate model
      %i[where joins includes merge all none].each do |method|
        define_method(method) do |*args, &block|
          user_model_for_queries.public_send(method, *args, &block)
        end
      end

      private

      def clear_extra_users(context)
        context.context_extra_users.destroy_all if context.persisted?
      end

      def ensure_context_persisted(context)
        context.save! unless context.persisted?
      end

      def write_users_by_mode(context, users)
        is_external_user = users.first.is_a?(Audiences::ExternalUser)

        if Audiences.config.dual_write_extra_users
          write_users_with_dual_write(context, users, is_external_user)
        elsif Audiences.config.use_configured_models
          context.extra_users_configured = users
        else
          context.extra_users_legacy = users
        end
      end

      def write_users_with_dual_write(context, users, is_external_user)
        if is_external_user
          write_legacy_users_with_dual_write(context, users)
        else
          write_configured_users_with_dual_write(context, users)
        end
      end

      # Dual-write helper: write configured users to both associations
      def write_configured_users_with_dual_write(context, users)
        user_ids = users.map(&:user_id)
        legacy_map = Audiences::ExternalUser.where(user_id: user_ids).index_by(&:user_id)

        context.context_extra_users.destroy_all

        users.each do |configured_user|
          legacy_user = legacy_map[configured_user.user_id]
          context.context_extra_users.create!(
            external_user_id: legacy_user&.id,
            configured_user_id: configured_user.id
          )
        end
      end

      # Dual-write helper: write legacy users to both associations
      def write_legacy_users_with_dual_write(context, users)
        user_ids = users.map(&:user_id)
        configured_map = find_configured_users_map(user_ids)

        context.context_extra_users.destroy_all

        users.each do |external_user|
          create_dual_write_record(context, external_user, configured_map)
        end
      end

      def find_configured_users_map(user_ids)
        return {} unless Audiences.config.user_model_class

        configured_model = Audiences.config.user_model_class.constantize
        configured_model.where(user_id: user_ids).index_by(&:user_id)
      end

      def create_dual_write_record(context, external_user, configured_map)
        configured_user = configured_map[external_user.user_id]
        context.context_extra_users.create!(
          external_user_id: external_user.id,
          configured_user_id: configured_user&.id
        )
      end

      def apply_scope(scope_proc, *args)
        scope_proc.call(model_class, *args)
      end
    end

    # Delegate attribute access to wrapped record
    def method_missing(method, ...)
      if @record.respond_to?(method)
        @record.public_send(method, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @record.respond_to?(method, include_private) || super
    end
  end
  # rubocop:enable Metrics/ClassLength
end
