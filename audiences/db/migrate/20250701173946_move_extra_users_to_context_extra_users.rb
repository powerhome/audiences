# frozen_string_literal: true

class MoveExtraUsersToContextExtraUsers < ActiveRecord::Migration[6.1]
  def up
    Audiences::Context.find_each do |context|
      next if context.extra_users_json.blank?

      users = Audiences::ExternalUser.from_scim(*context.extra_users_json)

      context.update!(extra_users: users)
    end
  end

  def down
    Audiences::Context.find_each do |context|
      next if context.extra_users.blank?

      context.update!(extra_users_json: context.extra_users.map(&:as_json))
    end
  end
end
