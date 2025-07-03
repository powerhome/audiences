# frozen_string_literal: true

module Audiences
  class GroupMembership < ApplicationRecord
    belongs_to :external_user
    belongs_to :group

    after_commit on: %i[create destroy] do
      relevant_groups = Audiences::Context.relevant_to(group)

      Audiences::Notifications.publish(*relevant_groups.to_a)
    end
  end
end
