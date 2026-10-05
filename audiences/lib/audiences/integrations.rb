# frozen_string_literal: true

module Audiences
  # Integration observers for syncing domain events from external identity providers
  # This module does NOT contain SCIM protocol logic (e.g., RFC 7644 operations)
  # It only contains observers that react to domain events and sync data to Audiences cache
  module Integrations
    # Domain event observers
    autoload :ObserverBase, "audiences/integrations/observer_base"
    autoload :UpsertGroupsObserver, "audiences/integrations/upsert_groups_observer"
    autoload :UpsertUsersObserver, "audiences/integrations/upsert_users_observer"
    autoload :DeleteGroupsObserver, "audiences/integrations/delete_groups_observer"
    autoload :DeleteUsersObserver, "audiences/integrations/delete_users_observer"
  end
end
