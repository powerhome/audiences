# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Usage

### Creating/Managing audiences

An audience is tied to an owning model withing your application. For the rest of this document we're going to assume a model Team. To create audiences for a team, using `audiences-react`, you'll render an audiences editor for your model.

That can be done with a unobstrusive JS renderer like react-rails, or a custom one as in [our dummy app](../audiences/spec/dummy/app/frontend/entrypoints/application.js). The editor will need two arguments:

- The context URI: `audience_context_url(owner)` helper
- The SCIM endpoint: `audience_scim_proxy_url` helper if using the [proxy](#configuring-the-scim-proxy), or the SCIM endpoint.

### Listening to audience changes

**TBD**

### Configuring the SCIM proxy

The Audience::ScimProxy should point to the real SCIM endpoint. The proxy allows you to configure the endpoint and the credentials/headers:

I.e.:

```ruby
# frozen_string_literal: true

require "audiences/scim_proxy"

Audiences::ScimProxy.config = {
  uri: "http://super-secret-scim.com/scim/v2/",
  headers: {
    "Authorization": "Beaer very-secret"
  }
  debug: $stdout,
}
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
