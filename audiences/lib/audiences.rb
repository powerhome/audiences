# frozen_string_literal: true

require "aether_observatory"

# Audiences system
# Audiences pushes notifications to your rails app when an
# identity provider updates a user, notifying matching audiences.
#
module Audiences
  autoload :Model, "audiences/model"
  autoload :Notifications, "audiences/notifications"
  autoload :Integrations, "audiences/integrations"
  autoload :ConfigurableAdapter, "audiences/configurable_adapter"
  autoload :VERSION, "audiences/version"

module_function

  # Updates the given context
  #
  # Params might contain:
  #
  # match_all: Boolean
  # criteria: { groups: Array<{ <group_type>: Array<{ id: Integer }> }> }
  #
  # @param token [String] a signed token (see #sign)
  # @param params [Hash] the updated params
  # @return Audience::Context
  #
  def update(key, criteria: [], extra_users: [], match_all: false)
    Audiences::Context.load(key) do |context|
      # Extract ids and external_ids from the extra_users hashes
      ids = extra_users.map { |h| h.with_indifferent_access[:id] }.compact
      external_ids = extra_users.map { |h| h.with_indifferent_access[:externalId] }.compact
      
      # Find users from configured model (supports both id and externalId lookups)
      model_class = ConfigurableAdapter.model_class
      users = if ids.any? && external_ids.any?
        model_class.where(id: ids).or(model_class.where(user_id: external_ids))
      elsif ids.any?
        model_class.where(id: ids)
      elsif external_ids.any?
        model_class.where(user_id: external_ids)
      else
        model_class.none
      end
      
      context.update!(
        match_all: match_all,
        extra_users: users,
        criteria: ::Audiences::Criterion.map(criteria.map(&:with_indifferent_access))
      )
    end
  end
end

require "audiences/configuration"
