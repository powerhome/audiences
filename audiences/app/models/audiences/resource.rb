# frozen_string_literal: true

module Audiences
  # @private
  class Resource < ApplicationRecord
    # Upserts all resource attributes and return
    # the resource objects
    #
    # @private
    def self.upsert_all!(list)
      list.map do |attrs|
        upsert!(**attrs)
      end
    end

    # Finds or creates a resource by id and type and updates it.
    #
    # @private
    def self.upsert!(resource_id:, resource_type:, **attrs)
      find_or_initialize_by(resource_id: resource_id,
                            resource_type: resource_type).tap do |resource|
        resource.update!(attrs)
      end
    end
  end
end
