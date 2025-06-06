module Audiences
  module Test
    module Factories
      def create_group(scim_id, **attrs)
        Audiences::Group.create!(scim_id: scim_id, display_name: "Group #{scim_id}",
                                external_id: scim_id, resource_type: "Groups", **attrs)
      end
    end
  end
end
