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
      # rubocop:disable Naming/PredicateName,Metrics/MethodLength,Metrics/AbcSize
      def has_audience(name)
        has_one :"#{name}_context", -> { where(relation: name) },
                as: :owner, dependent: :destroy,
                class_name: "Audiences::Context"
        has_many :"#{name}_external_users",
                 through: :"#{name}_context", source: :users,
                 class_name: "Audiences::ExternalUser"
        has_many name, -> { readonly }, through: :"#{name}_external_users", source: :identity

        scope :"with_#{name}", -> { includes(name) }
        scope :"with_#{name}_context", -> { includes(:"#{name}_context") }
        scope :"with_#{name}_external_users", -> { includes(:"#{name}_external_users") }

        after_initialize if: :new_record? do
          association(:"#{name}_context").build
        end
      end
      # rubocop:enable Naming/PredicateName,Metrics/MethodLength,Metrics/AbcSize
    end
  end
end
