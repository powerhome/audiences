# frozen_string_literal: true

module Audiences
  module Test
    module Factories
      def next_id
        @next_id ||= 0
        @next_id += 1
      end

      def create_group(scim_id: next_id, **attrs)
        Audiences::Group.create!(scim_id: scim_id, display_name: "Group #{scim_id}",
                                 external_id: scim_id, resource_type: "Groups", **attrs)
      end
    end
  end
end
