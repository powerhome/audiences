# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

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

An audience is tied to an owning model within your application. In this document, we'll use a `Team` model as an example. To create audiences for a team using `audiences-react`, render an audiences editor for your model.

This can be done with an unobtrusive JS renderer like `react-rails` or a custom one as shown in [our dummy app](../audiences/spec/dummy/app/frontend/entrypoints/application.js). The editor requires two arguments:

- The context URI: `audience_context_url(owner, relation)` helper
- The SCIM endpoint: `audience_scim_proxy_url` helper if using the [proxy](#configuring-the-scim-proxy), or the SCIM endpoint directly.

### Configuring Audiences

The `Audience.config.scim` should point to the SCIM endpoint. Configure the endpoint and the credentials/headers as follows:

```ruby
Audiences.configure do |config|
  config.scim = {
    uri: ENV.fetch("SCIM_V2_API"),
    headers: { "Authorization" => "Bearer #{ENV.fetch('SCIM_V2_TOKEN')}" }
  }
end
```

### Adding Audiences to a Model

A model object can contain multiple audience contexts using the `has_audience` module helper, which is added to ActiveRecord automatically when configured:

```ruby
Audiences.configure do |config|
  config.identity_class = "User"
  config.identity_key = "login"
end
```

The `identity_class` represents the SCIM user within the app domain, and the `identity_key` maps directly to the SCIM User's `externalId`.

Once configured, add audience contexts to a model:

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

### SCIM Resource Attributes

Configure which attributes are requested from the SCIM backend for each resource type. `Audiences` includes `id`, `externalId`, and `displayName` by default in every resource type. It also requests `photos.type` and `photos.value` for users by default. To request additional attributes:

```ruby
Audiences.configure do |config|
  config.resource :Users, attributes: ["name" => %w[givenName familyName formatted]]
  config.resource :Groups, attributes: %w[mfaRequired]
end
```

## Contributing

For more information, see the [development guide](../../docs/development.md).

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).