# frozen_string_literal: true

module Audiences
  # ConfigurableAdapter provides a flexible adapter pattern that allows
  # Audiences to work with any data source by configuring transformation
  # and scope procs in the initializer.
  #
  # This eliminates the need to modify source models (like TwoPercent::ScimUser)
  # and keeps all integration logic in the consuming application's configuration.
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
    def scim_id
      to_audiences_hash[:scim_id]
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

    class << self
      # Returns the configured model class (e.g., TwoPercent::ScimUser)
      def model_class
        Audiences.config.user_model_class
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

      # Find records by SCIM IDs
      def audiences_find_by_scim_ids(scim_ids)
        model_class.where(scim_id: scim_ids)
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
