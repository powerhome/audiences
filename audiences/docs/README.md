# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Usage

### Creating/Managing audiences

An audience is tied to an owning model withing your application. For the rest of this document we're going to assume a model Team. To create audiences for a team, using `audiences-react`, you'll render an audiences editor for your model.

That can be done with a unobstrusive JS renderer like react-rails, or a custom one as in [our dummy app](../audiences/spec/dummy/app/frontend/entrypoints/application.js). The editor will need two arguments:

- The context URI: `audience_context_url(owner)` helper
- The SCIM endpoint: `audience_scim_proxy_url` helper if using the [proxy](#configuring-the-scim-proxy), or the SCIM endpoint.

### Configuring the SCIM backend

The Audience::Scim should point to the real SCIM endpoint. The service allows you to configure the endpoint and the credentials/headers:

I.e.:

```ruby
Audiences::Scim.client = Audiences::Scim::Client.new(
  uri: ENV.fetch("SCIM_V2_API"),
  headers: { "Authorization" => "Bearer #{ENV.fetch('SCIM_V2_TOKEN')}" }
)
```

### Listening to audience changes

The goal of audiences is to allow the app to keep up with a mutable group of people. To allow that, `Audiences` includes the `Audiences::Notifications` module, to allow the hosting app to subscribe to audiences related to a certain owner type, and react to that through a block:

```ruby
Rails.application.config.to_prepare do
  Audiences::Notifications.subscribe Team do |context|
    team.update_memberships(context.users)
  end
end
```

or scheduling an AcitiveJob:

```ruby
Rails.application.config.to_prepare do
  Audiences::Notifications.subscribe Group, job: UpdateGroupMembershipsJob
  Audiences::Notifications.subscribe Team, job: UpdateTeamMembershipsJob.set(queue: "low")
end
```

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

## Contributing

See [development guide](../../docs/development.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
