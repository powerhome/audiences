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
      # Returns the strategy instance
      # Strategy handles routing between legacy and configured models
      def strategy
        if Audiences.config.use_configured_models
          ConfiguredStrategy.new(Audiences.config)
        else
          LegacyStrategy.new
        end
      end

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
      def active_audiences_users
        strategy.active_users
      end

      # Returns relation filtered by group membership
      def audiences_members_of(groups)
        strategy.members_of(groups)
      end

      # Find users by their IDs from the source system
      # @param ids [Array<String>] Array of user IDs from source system
      # @return [ActiveRecord::Relation] Users matching the given IDs
      def audiences_find_by_ids(ids)
        return strategy.none if ids.blank?

        strategy.find_by_ids(ids) # rubocop:disable Rails/DynamicFindBy - Strategy method, not AR dynamic finder
      end

      # Find users by their IDs or external IDs
      # @param ids [Array<String>] Array of primary IDs
      # @param external_ids [Array<String>] Array of external IDs
      # @return [ActiveRecord::Relation] Users matching the given IDs
      def find_by_identifiers(ids:, external_ids:)
        strategy.find_by_identifiers(ids: ids, external_ids: external_ids)
      end

      # Find groups from criterion data
      # @param resource_type [String] The resource type (e.g., "Departments", "Territories")
      # @param group_data [Array<Hash>] Array of group hashes with "id" or "externalId" keys
      # @return [Array] Array of group records (configured model or Audiences::Group)
      delegate :find_groups, to: :strategy

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
      # @param context [Audiences::Context] The context to get users from
      # @return [ActiveRecord::Relation] User records from appropriate association
      delegate :get_users_from_context, to: :strategy

      # Find users matching criterion groups (AND logic across resource types)
      # @param groups [Array] Array of group records
      # @return [ActiveRecord::Relation] Users matching the groups
      def matching(groups)
        strategy.matching(groups)
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
