# frozen_string_literal: true

module Audiences
  # Finds the application's identity record for each of a set of users.
  #
  # The users are matched to identities by the keys the source reports
  # (Audiences.source.identity_keys), so the gem never assumes the key is a
  # column of the users themselves.
  class IdentityLookup
    def initialize(identity_class: Audiences.config.identity_class.constantize,
                   identity_key: Audiences.config.identity_key,
                   source: Audiences.source)
      @identity_class = identity_class
      @identity_key = identity_key
      @source = source
    end

    # @return [Array<ApplicationRecord, nil>] one identity per user, in the users'
    #   order, nil for a user without one
    def identities_of(users)
      keys = keys_of(users)

      identities_by_key(keys.compact).values_at(*keys)
    end

  private

    # The source reports its own values, for example the String "12" from a
    # `user_id` string column, while the identity class holds the key typed, for
    # example the Integer 12. The identities are matched to the keys in Ruby, where
    # "12" and 12 are different hash keys, so each key is cast to the type of the
    # identity's key column. Without the cast no user would match its identity.
    def keys_of(users)
      type = @identity_class.type_for_attribute(@identity_key.to_s)

      @source.identity_keys(users).map { |key| type.cast(key) }
    end

    def identities_by_key(keys)
      @identity_class.where(@identity_key => keys).index_by(&@identity_key)
    end
  end
end
