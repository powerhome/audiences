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

#### Read Source

The read source backs the resource endpoint, `GET /scim(/*scim_path)`. `ScimProxyController#get` renders whatever the configured source returns:

```ruby
render json: Audiences.read_source.fetch(
  resource_type: params[:scim_path],
  query: params[:query],
  start_index: params[:startIndex],
  count: params[:count]
)
```

`Audiences.config.read_source` defaults to `Audiences::ReadSources::Legacy`, which reads Audiences' own `ExternalUser` and `Group` projection. Replacing it with any object that satisfies the `#fetch` contract below lets reads come from another store without Audiences depending on that store.

That covers only this endpoint. The context endpoints (`GET /:key` and `GET /:key/users`) and audience calculation keep reading the local projection no matter what the read source does.

Assign a replacement from an initializer:

```ruby
Audiences.configure do |config|
  config.read_source = MyReadSource.new
end
```

When the implementation is an autoloaded constant, assign it inside a `to_prepare` block so each reload picks up the new class. Keep the block inside `configure` so `config` stays in scope:

```ruby
Audiences.configure do |config|
  Rails.application.config.to_prepare do
    config.read_source = MyReadSource.new
  end
end
```

##### The `#fetch` contract

```ruby
def fetch(resource_type:, query:, start_index:, count:)
```

All four arguments come straight from request params with no casting or defaulting, so each one is a `String` or `nil`.

- `resource_type` is the wildcard path segment: `"Users"`, `"Groups"`, `"Departments"`, and so on. The segment is optional in the route, so `GET /scim` passes `nil`.
- `query` is a substring to match against the display name. `nil` applies no filter.
- `start_index` is an offset and `count` is a limit, both as strings such as `"2"`. `nil` means no restriction, so omitting `count` returns the whole catalogue. A source doing arithmetic on either has to call `to_i` first.

##### The return contract

Return a collection `render json:` can serialize: an `ActiveRecord::Relation`, serialized through each record's `as_json`, or an array of hashes rendered as given.

Every resource type except `"Users"` returns elements of this shape, where `id` is the SCIM id rather than the primary key:

```json
{ "id": "<scim_id>", "externalId": "<external_id>", "displayName": "<display_name>" }
```

A `"Users"` element is the stored SCIM data plus these keys, derived from the user's group memberships:

```json
{
  "groups": [{ "value": "<group scim_id>", "display": "<group display_name>" }],
  "title": "<Titles group display name>",
  "urn:ietf:params:scim:schemas:extension:authservice:2.0:User": {
    "role": "<Roles group display name>",
    "department": "<Departments group display name>",
    "territory": "<Territories group display name>",
    "territoryAbbr": "<territory_abbreviations lookup>"
  }
}
```

That payload is then filtered to the keys in `exposed_user_attributes`, which holds string keys and defaults to `id`, `externalId`, `displayName`, and `photos`. The filter drops any configured key the payload lacks, so listing `title`, `groups`, or the extension URN only works if the source emits them. Legacy builds all of this in `ExternalUser#as_scim`.

##### Scopes

Legacy applies the configured scopes inside `#fetch`. The controller does not:

```ruby
if resource_type == "Users"
  ExternalUser.instance_exec(&Audiences.default_users_scope)
else
  Group.where(resource_type: resource_type).instance_exec(&Audiences.default_groups_scope)
end
```

Both default to `-> { active }`. A replacement source has to apply them itself; skipping them serves inactive records and bypasses whatever membership restriction the application configured.

Each proc is `instance_exec`'d against whatever relation the calling code holds, and there is one `default_users_scope` for the whole gem — the context endpoints always run it against `ExternalUser`. A proc may therefore only call scopes that exist on every model it reaches, and a source backed by another model needs equivalent scopes defined there.

#### Adding Audiences to a Model

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

#### Listening to Audience Changes

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
