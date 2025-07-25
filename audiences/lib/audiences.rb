# frozen_string_literal: true

require "aether_observatory"

# Audiences system
# Audiences pushes notifications to your rails app when a
# SCIM backend updates a user, notifying matching audiences.
#
module Audiences
  autoload :Model, "audiences/model"
  autoload :Notifications, "audiences/notifications"
  autoload :Scim, "audiences/scim"
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
      context.update!(
        match_all: match_all,
        extra_users: ::Audiences::ExternalUser.from_scim(*extra_users.map(&:with_indifferent_access)),
        criteria: ::Audiences::Criterion.map(criteria.map(&:with_indifferent_access))
      )
    end
  end
end

require "audiences/configuration"
