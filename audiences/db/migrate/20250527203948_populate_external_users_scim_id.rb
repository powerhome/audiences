# frozen_string_literal: true

class PopulateExternalUsersScimId < ActiveRecord::Migration[6.1]
  def down; end

  def up
    Audiences::ExternalUser.unscoped.find_each do |user|
      user.update!(
        scim_id: user.data&.fetch("id", nil),
        display_name: user.data&.fetch("displayName", nil),
        picture_urls: user.data&.fetch("photos", [])&.pluck("value")
      )
    end
  end
end
