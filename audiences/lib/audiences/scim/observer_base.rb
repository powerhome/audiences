# frozen_string_literal: true

module Audiences
  module Scim
    class InvalidGroupsError < StandardError
    end

    class ObserverBase < AetherObservatory::ObserverBase
    end
  end
end
