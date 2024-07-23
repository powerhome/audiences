# frozen_string_literal: true

module Audiences
  module Model
    extend ActiveSupport::Concern

    class_methods do
      #
      # Adds relationships between the audience context and the owner object
      #
      # @param name [Symbol,String] the member relationship name
      #
      def has_audience(name) # rubocop:disable Naming/PredicateName
        has_one :"#{name}_context", -> { where(relation: name) },
                as: :owner, dependent: :destroy,
                class_name: "Audiences::Context"
        has_many :"#{name}_external_users",
                 through: :"#{name}_context", source: :users,
                 class_name: "Audiences::ExternalUser"
        has_many name, -> { readonly }, through: :"#{name}_external_users", source: :identity

        after_initialize if: :new_record? do
          association(:"#{name}_context").build
        end
      end
    end
  end
end
