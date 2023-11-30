# frozen_string_literal: true

class UpdateMembershipsJob < ApplicationJob
  def perform(context)
    memberships = context.users.map do |user|
      ExampleMembership.new(
        user_id: user["id"],
        name: user["displayName"],
        photo: user.dig("photos", 0, "value")
      )
    end
    context.owner.update!(memberships: memberships)
  end
end
