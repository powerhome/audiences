# frozen_string_literal: true

module Audiences
  class Context
    module Locating
      extend ActiveSupport::Concern

      SIGNED_GID_RESOURCE = "audiences"

      class_methods do
        # Finds or creates a context for the given owner/relation
        #
        # @private
        # @param owner [Class<ActiveRecord::Base>] an active record owning the context
        # @Param relation [String,Symbol] a context relation (i.e.: :members)
        # @return [Audiences::Context]
        def for(owner, relation: nil)
          where(owner: owner, relation: relation).first_or_create!
        end

        # Loads a context given a signed GlobalID key
        #
        # @private
        # @param key [String] signed GlobalID key
        # @return [Audiences::Context]
        # @yield [Audiences::Context]
        def load(key)
          GlobalID::Locator.locate_signed(key, for: SIGNED_GID_RESOURCE).tap do |ctx|
            yield ctx if block_given?
          end
        end
      end

      def signed_key
        to_sgid(for: SIGNED_GID_RESOURCE).to_s
      end
    end
  end
end
