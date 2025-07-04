# frozen_string_literal: true

module Audiences
  module Scim
    autoload :ScimData, "audiences/scim/scim_data"
    autoload :FieldMapping, "audiences/scim/field_mapping"
    autoload :PatchOp, "audiences/scim/patch_op"

    autoload :ObserverBase, "audiences/scim/observer_base"
    autoload :PatchGroupsObserver, "audiences/scim/patch_groups_observer"
    autoload :PatchUsersObserver, "audiences/scim/patch_users_observer"
    autoload :UpsertGroupsObserver, "audiences/scim/upsert_groups_observer"
    autoload :UpsertUsersObserver, "audiences/scim/upsert_users_observer"
  end
end
