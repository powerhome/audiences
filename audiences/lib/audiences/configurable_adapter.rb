# frozen_string_literal: true

module Audiences
  # ConfigurableAdapter provides a flexible adapter pattern that allows
  # Audiences to work with any data source by configuring transformation
  # and scope procs in the initializer.
  #
  # This eliminates the need to modify source models and keeps all
  # integration logic in the consuming application's configuration.
  class ConfigurableAdapter
    def initialize(record)
      @record = record
      @hash = nil
    end

    # Transform record to hash format expected by Audiences
    # Uses configured transformation proc
    def to_audiences_hash
      @hash ||= Audiences.config.to_audiences_hash_proc.call(@record)
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

    alias_method :eql?, :==

    def hash
      id.hash
    end

    class << self
      # Returns the configured model class
      # Supports both Class objects and String class names (constantized lazily)
      def model_class
        klass = Audiences.config.user_model_class
        klass.is_a?(String) ? klass.constantize : klass
      end

      # Returns relation with active users eligible for audiences
      # Applies configured active users scope
      def active_audiences_users
        apply_scope(Audiences.config.active_users_scope_proc)
      end

      # Returns relation filtered by group membership
      # Applies configured members_of scope
      def audiences_members_of(groups)
        apply_scope(Audiences.config.members_of_scope_proc, groups)
      end

      # Find users by their IDs from the source system
      # Uses configured find_by_ids_proc to avoid hardcoding column names
      # @param ids [Array<String>] Array of user IDs from source system
      # @return [ActiveRecord::Relation] Users matching the given IDs
      def audiences_find_by_ids(ids)
        return none if ids.blank?
        apply_scope(Audiences.config.find_by_ids_proc, ids)
      end

      # Support ActiveRecord query methods by delegating to model_class
      %i[where joins includes merge all none].each do |method|
        define_method(method) do |*args, &block|
          model_class.public_send(method, *args, &block)
        end
      end

      private

      def apply_scope(scope_proc, *args)
        scope_proc.call(model_class, *args)
      end
    end

    # Delegate attribute access to wrapped record
    def method_missing(method, *args, &block)
      if @record.respond_to?(method)
        @record.public_send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @record.respond_to?(method, include_private) || super
    end
  end
end
