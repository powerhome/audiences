# frozen_string_literal: true

module Audiences
  class IdentityResolver
    def initialize(source: Audiences.source)
      @source = source
      @identity_class = Audiences.config.identity_class.to_s.constantize
      @identity_key = Audiences.config.identity_key
      @identity_type = @identity_class.type_for_attribute(@identity_key.to_s)
    end

    def resolve(users:)
      values = @source.identity_values_for(users: users).map { |value| cast_identity_value(value) }
      identities = @identity_class.where(@identity_key => values.compact).index_by do |identity|
        identity.public_send(@identity_key)
      end
      values.map { |value| identities[value] unless value.nil? }
    end

  private

    def cast_identity_value(value)
      @identity_type.deserialize(@identity_type.serialize(value))
    end
  end
end
