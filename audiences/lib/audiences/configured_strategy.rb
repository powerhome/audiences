# frozen_string_literal: true

module Audiences
  # ConfiguredStrategy encapsulates all query logic for configured models
  # This strategy is used when use_configured_models is true
  class ConfiguredStrategy
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def active_users
      config.active_users_scope_proc.call(user_model)
    end

    def members_of(groups)
      config.members_of_scope_proc.call(user_model, groups)
    end

    def find_by_ids(ids)
      config.find_by_ids_proc.call(user_model, ids)
    end

    def find_by_identifiers(ids:, external_ids:)
      if ids.any? && external_ids.any?
        user_model.where(id: ids).or(user_model.where(user_id: external_ids))
      elsif ids.any?
        user_model.where(id: ids)
      elsif external_ids.any?
        user_model.where(user_id: external_ids)
      else
        user_model.none
      end
    end

    def find_groups(resource_type, group_data)
      config.find_groups_proc.call(resource_type, group_data)
    end

    def get_users_from_context(context)
      context.extra_users_configured
    end

    delegate :none, to: :user_model

    def matching(groups)
      return user_model.none if groups.empty?

      # AND logic: user must be member of at least one group from EACH resource type
      groups.group_by(&:resource_type).values.reduce(user_model.all) do |scope, resource_groups|
        config.members_of_scope_proc.call(user_model, resource_groups).merge(scope)
      end
    end

  private

    def user_model
      klass = config.user_model_class
      klass.is_a?(String) ? klass.constantize : klass
    end
  end
end
