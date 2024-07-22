# frozen_string_literal: true

# Audiences system
# Audiences pushes notifications to your rails app when a
# SCIM backend updates a user, notifying matching audiences.
#
module Audiences
  autoload :Notifications, "audiences/notifications"
  autoload :Scim, "audiences/scim"
  autoload :VERSION, "audiences/version"

  GID_RESOURCE = "audiences"

module_function

  # Provides a key to load an audience context for the given owner.
  # An owner should implment GlobalID::Identification.
  #
  # @param owner [GlobalID::Identification] an owning model
  # @return [String] context key
  #
  def sign(owner, relation: nil)
    ::Audiences::Context.for(owner, relation: relation)
                        .to_sgid(for: GID_RESOURCE)
  end

  # Loads a context for the given context key
  #
  # @param token [String] a signed token (see #sign)
  # @return Audience::Context
  #
  def load(key)
    locate_context(key, &:readonly!)
  end

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
    locate_context(key) do |context|
      context.update!(
        criteria: ::Audiences::Criterion.map(criteria),
        **attrs
      )
      context.refresh_users!
      context.readonly!
    end
  end

  private_class_method def locate_context(key, &block)
    GlobalID::Locator.locate_signed(key, for: GID_RESOURCE)
                     .tap(&block)
  end
end

require "audiences/configuration"
