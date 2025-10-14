# frozen_string_literal: true

return unless Rails.env.development?

# Seed data for development environment

territory = Audiences::Group.find_or_create_by!(
  resource_type: "Territories",
  external_id: "PHL"
) do |g|
  g.display_name = "Philadelphia"
  g.scim_id = "PHL"
end

territory2 = Audiences::Group.find_or_create_by!(
  resource_type: "Territories",
  external_id: "NYC"
) do |g|
  g.display_name = "New York"
  g.scim_id = "NYC"
end

department = Audiences::Group.find_or_create_by!(
  resource_type: "Departments",
  external_id: "CD"
) do |g|
  g.display_name = "Customer Development"
  g.scim_id = "CD"
end

department2 = Audiences::Group.find_or_create_by!(
  resource_type: "Departments",
  external_id: "BT"
) do |g|
  g.display_name = "Business Technology"
  g.scim_id = "BT"
end

title = Audiences::Group.find_or_create_by!(
  resource_type: "Titles",
  external_id: "CA"
) do |g|
  g.display_name = "Confirmation Agent"
  g.scim_id = "CA"
end

title2 = Audiences::Group.find_or_create_by!(
  resource_type: "Titles",
  external_id: "DEV"
) do |g|
  g.display_name = "Developer"
  g.scim_id = "DEV"
end

# Create users with minimal data - let the model handle SCIM formatting
users_data = [
  {
    user_id: "75279",
    scim_id: "3888",
    display_name: "Talinda Barnett",
    picture_url: "",
    data: {
      "id" => "3888",
      "externalId" => "75279",
      "displayName" => "Talinda Barnett",
      "userName" => "talinda.barnett",
      "photos" => [
        { "type" => "photo", "value" => "", "primary" => true },
      ],
      "active" => true,
    },
    groups: [territory, department, title],
  },
  {
    user_id: "168425",
    scim_id: "34158",
    display_name: "Kseniia Khodyreva",
    picture_url: "",
    data: {
      "id" => "34158",
      "externalId" => "168425",
      "displayName" => "Kseniia Khodyreva",
      "userName" => "u34158",
      "photos" => [
        { "type" => "photo", "value" => "", "primary" => true },
      ],
      "active" => true,
    },
    groups: [territory, department2, title2],
  },
  {
    user_id: "12345",
    scim_id: "5678",
    display_name: "John Smith",
    picture_url: "",
    data: {
      "id" => "5678",
      "externalId" => "12345",
      "displayName" => "John Smith",
      "userName" => "john.smith",
      "photos" => [
        { "type" => "photo", "value" => "", "primary" => true },
      ],
      "active" => true,
    },
    groups: [territory2, department2, title2],
  },
  {
    user_id: "67890",
    scim_id: "9101",
    display_name: "Sarah Johnson",
    picture_url: "",
    data: {
      "id" => "9101",
      "externalId" => "67890",
      "displayName" => "Sarah Johnson",
      "userName" => "sarah.johnson",
      "photos" => [
        { "type" => "photo", "value" => "", "primary" => true },
      ],
      "active" => true,
    },
    groups: [territory2, department, title],
  },
]

users_data.each do |user_data|
  user = Audiences::ExternalUser.find_or_create_by!(
    user_id: user_data[:user_id]
  ) do |u|
    u.scim_id = user_data[:scim_id]
    u.display_name = user_data[:display_name]
    u.picture_url = user_data[:picture_url]
    u.active = true
    u.data = user_data[:data]
  end

  user_data[:groups].each do |group|
    Audiences::GroupMembership.find_or_create_by!(
      external_user_id: user.id,
      group_id: group.id
    )
  end
end
