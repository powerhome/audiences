# Audiences

A provider-agnostic audience management gem for Rails applications. Calculate and react to dynamic user groups based on identity provider data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "audiences"
```

Then execute:

```bash
$ bundle install
```

Or install it yourself with:

```bash
$ gem install audiences
```

## Usage

### Creating/Managing Audiences

An audience is tied to an owning model within your application. In this document, we'll use a `Team` model as an example. To create audiences for a team use the `audiences-ujs` package bundled with the gem. Render the audiences editor in your view as follows:

```erb
<%= javascript_include_tag "audiences-ujs", defer: true %>
<%= render_audiences_editor(@example_owner.members_context) %>
```

This eliminates the need for `audiences-react` as a separate dependency.

### Required Arguments:
- **Context**: Example: `owner.members_context`

For more details, refer to [editor_helper](../lib/audiences/editor_helper.rb).

### Configuring Audiences

#### Configuring Identity Models (Required)

**BREAKING CHANGE (v2.0):** Audiences no longer owns identity models. You must configure your application's user and group models.

Audiences uses an adapter pattern to work with your application's identity models (users, groups, memberships). This allows Audiences to work with any identity provider (SCIM, LDAP, OAuth, etc.) without being tightly coupled to a specific implementation.

##### Required Model Interface

Your user and group models must provide:

**User Model Requirements:**
- Attributes: `id` (unique identifier), `external_id`, `display_name`, `active` (boolean)
- Scopes:
  - `.active` - returns only active users
  - `.members_of(groups)` - filters users who are members of given groups
- Associations: `has_many :groups` (association to your group model)

**Group Model Requirements:**
- Attributes: `id` (unique identifier), `display_name`, `resource_type`

##### Configuration Example

Configure Audiences in an initializer (`config/initializers/audiences.rb`):

```ruby
Audiences.configure do |config|
  # 1. Specify your user and group model classes
  # Use string class names to avoid load order issues
  config.user_model_class = "MyApp::User"
  config.group_model_class = "MyApp::Group"

  # 2. Define how to transform a user record to Audiences format
  config.to_audiences_hash_proc = ->(user) {
    {
      id: user.id,                         # Unique identifier from your identity provider
      external_id: user.external_id,       # External identifier (e.g., employee ID)
      display_name: user.display_name,     # Display name
      active: user.active,                 # Boolean active status
      groups: user.groups.map { |g|        # Array of group hashes
        {
          id: g.id,
          display_name: g.display_name,
          resource_type: g.resource_type
        }
      }
    }
  }

  # 3. Define scope for active users eligible for audiences
  config.active_users_scope_proc = ->(relation) {
    relation.where(active: true)
  }

  # 4. Define scope to filter users by group membership
  config.members_of_scope_proc = ->(relation, groups) {
    relation
      .joins(:group_memberships)
      .where(group_memberships: { group_id: groups })
      .distinct
  }

  # 5. Define how to find users by IDs
  config.find_by_ids_proc = ->(relation, ids) {
    relation.where(id: ids)
  }
end
```

**Provider-Agnostic Design:** The adapter uses generic field names (`id`, `groups`, etc.) that work with any identity provider. To switch providers, just update your configuration procs - no changes to Audiences internals needed.

**Real-World Examples:**
- SCIM Provider: Maps `scim_id` (or whatever your IdP id is called) → `id`
- Test Configuration: [See dummy app](../spec/dummy/config/initializers/audiences.rb)
- LDAP Provider: Map `dn` → `id`, `memberOf` → `groups`
- OAuth Provider: Map `sub` → `id`, `roles` → `groups`

### Adding Audiences to a Model

A model object can contain multiple audience contexts using the `has_audience` module helper:

```ruby
class Survey < ApplicationRecord
  has_audience :responders
  has_audience :supervisors
end
```

### Listening to Audience Changes

Audiences allows your app to keep up with mutable groups of people. To react to audience changes, subscribe to audiences related to a certain owner type and handle changes through a block:

```ruby
Audiences.configure do |config|
  config.notifications do
    subscribe Team do |context|
      team.update_memberships(context.users)
    end
  end
end
```

Or schedule an ActiveJob:

```ruby
Audiences.configure do |config|
  config.notifications do
    subscribe Group, job: UpdateGroupMembershipsJob
    subscribe Team, job: UpdateTeamMembershipsJob.set(queue: "low")
  end
end
```

The notifications block is executed every time the app is loaded or reloaded through a `to_prepare` block, allowing autoloaded constants such as model and job classes to be referenced.

See a working example in our dummy app:

- [Initializer](../spec/dummy/config/initializers/audiences.rb)
- [Job class](../spec/dummy/app/jobs/update_memberships_job.rb)
- [Example owning model](../spec/dummy/app/models/example_owner.rb)

## Contributing

For more information, see the [development guide](../../docs/development.md).

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
