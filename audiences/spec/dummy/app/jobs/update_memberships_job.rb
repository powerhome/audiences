# frozen_string_literal: true

class UpdateMembershipsJob < ApplicationJob
  def perform(context)
    memberships = context.users.map do |user|
      ExampleMembership.new(
        user_id: user.user_id,
        name: user.data["displayName"],
        photo: user.data.dig("photos", 0, "value")
      )
    end
    context.owner.update!(memberships: memberships)
  end
end
