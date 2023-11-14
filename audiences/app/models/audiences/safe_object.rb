# frozen_string_literal: true

module Audiences
  SafeObject = Struct.new(:id, :displayName, :photos) do
    def initialize(attrs)
      super attrs["id"], attrs["displayName"], attrs["photos"]
    end
  end
end
