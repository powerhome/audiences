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
      # rubocop:disable Naming/PredicateName,Metrics/MethodLength
      def has_audience(name)
        has_one :"#{name}_context", -> { where(relation: name) },
                as: :owner, dependent: :destroy,
                class_name: "Audiences::Context"

        delegate :users, to: :"#{name}_context", prefix: :"#{name}_external"

        define_method(name) do
          send(:"#{name}_context").users.includes(:identity)
                                        .map(&:identity)
        end

        scope :"with_#{name}_context", -> { includes(:"#{name}_context") }

        after_initialize if: :new_record? do
          association(:"#{name}_context").build
        end
      end
      # rubocop:enable Naming/PredicateName,Metrics/MethodLength
    end
  end
end
