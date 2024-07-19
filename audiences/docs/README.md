# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "audiences"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install audiences
```

## Usage

### Creating/Managing audiences

An audience is tied to an owning model withing your application. For the rest of this document we're going to assume a model Team. To create audiences for a team, using `audiences-react`, you'll render an audiences editor for your model.

That can be done with a unobstrusive JS renderer like react-rails, or a custom one as in [our dummy app](../audiences/spec/dummy/app/frontend/entrypoints/application.js). The editor will need two arguments:

- The context URI: `audience_context_url(owner)` helper
- The SCIM endpoint: `audience_scim_proxy_url` helper if using the [proxy](#configuring-the-scim-proxy), or the SCIM endpoint.

### Configuring Audiences

The Audience::Scim should point to the SCIM endpoint. The service allows you to configure the endpoint and the credentials/headers:

I.e.:

```ruby
Audiences.configure do |config|
  config.scim = {
    uri: ENV.fetch("SCIM_V2_API"),
    headers: { "Authorization" => "Bearer #{ENV.fetch('SCIM_V2_TOKEN')}" }
  }
end
```

#### Listening to audience changes

The goal of audiences is to allow the app to keep up with a mutable group of people. To allow that, `Audiences` allows the hosting app to subscribe to audiences related to a certain owner type, and react to that through a block:

```ruby
Audiences.configure do |config|
  config.notifications do
    subscribe Team do |context|
      team.update_memberships(context.users)
    end
  end
end
```

or scheduling an AcitiveJob:

```ruby
Audiences.configure do |config|
  config.notifications do
    subscribe Group, job: UpdateGroupMembershipsJob
    subscribe Team, job: UpdateTeamMembershipsJob.set(queue: "low")
  end
end
```

Notice that the notifications block is executed every time the app is loaded or reloaded, through a `to_prepare` block. This allows autoloaded constants such as model and job classes to be referenced.

You can find a working example in our dummy app:

- [initializer](../spec/dummy/config/initializers/audiences.rb)
- [job class](../spec/dummy/app/jobs/update_memberships_job.rb)
- [example owning model](../spec/dummy/app/models/example_owner.rb.rb)

#### SCIM resource attributes

You can configure which attributes are going to be requested to the SCIM backend for each resource type. Audiences requires that at least `id` and `displayName` are requested, and also requests `photos` for users by default. But you might want to request extra attributes to use them directly from `Audiences::ExternalUser`. This is possible using the `resource` configuration helper:

```ruby
Audiences.configure do |config|
  config.resource :Users, attributes: "id,displayName,photos,name"
  config.resource :Groups, attributes: "id,displayName,mfaRequired"
end
```

## Contributing

See [development guide](../../docs/development.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
