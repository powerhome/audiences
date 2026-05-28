# frozen_string_literal: true

module Audiences
  # Integration observers for handling domain events from external identity providers
  # Observers handle deletion events to clean up related audience data
  module Integrations
    # Domain event observers
    autoload :ObserverBase, "audiences/integrations/observer_base"
    autoload :DeleteGroupsObserver, "audiences/integrations/delete_groups_observer"
    autoload :DeleteUsersObserver, "audiences/integrations/delete_users_observer"
  end
end
