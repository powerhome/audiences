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
  autoload :LegacyStrategy, "audiences/legacy_strategy"
  autoload :ConfiguredStrategy, "audiences/configured_strategy"
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
      users = find_extra_users(extra_users)

      context.update!(
        match_all: match_all,
        extra_users: users,
        criteria: ::Audiences::Criterion.map(criteria.map(&:with_indifferent_access))
      )
    end
  end

  def find_extra_users(extra_users_hashes)
    ids, external_ids = extract_user_identifiers(extra_users_hashes)
    ConfigurableAdapter.find_by_identifiers(ids: ids, external_ids: external_ids)
  end
  module_function :find_extra_users

  def extract_user_identifiers(extra_users_hashes)
    ids = extra_users_hashes.filter_map { |h| h.with_indifferent_access[:id] }
    external_ids = extra_users_hashes.filter_map { |h| h.with_indifferent_access[:externalId] }
    [ids, external_ids]
  end
  module_function :extract_user_identifiers
end

require "audiences/configuration"
