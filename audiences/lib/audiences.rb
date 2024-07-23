# frozen_string_literal: true

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
  # criteria: Array<{ <group_type>: Array<Integer> }>
  #
  # @param token [String] a signed token (see #sign)
  # @param params [Hash] the updated params
  # @return Audience::Context
  #
  def update(key, criteria: [], **attrs)
    Audiences::Context.load(key) do |context|
      context.update!(
        criteria: ::Audiences::Criterion.map(criteria),
        **attrs
      )
    end
  end
end

require "audiences/configuration"
