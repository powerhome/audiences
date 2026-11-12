# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Installation

Requires Ruby 3.1 or newer and Rails 7.2 or newer. Rails versions may impose a higher Ruby requirement; the Rails 8.1 development bundle requires Ruby 3.2 or newer.

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

#### Source

`Audiences.source` is the one seam through which Audiences reads users and groups. It backs the resource endpoint (`GET /scim(/*scim_path)`), the context endpoints (`GET /:key` and `GET /:key/users`), audience calculation, and the `has_audience` readers. `ScimProxyController#get` renders whatever `#fetch` returns:

```ruby
render json: Audiences.source.fetch(
  resource_type: params[:scim_path],
  query: params[:query],
  start_index: params[:startIndex],
  count: params[:count]
)
```

`Audiences.config.source` holds the adapter, the object that implements the port below, and `Audiences.source` returns it. It defaults to `Audiences::Sources::Legacy`, which reads Audiences' own `ExternalUser` and `Group` projection. Replacing it with another adapter lets reads come from another store without Audiences depending on that store.

Assign a replacement from an initializer:

```ruby
Audiences.configure do |config|
  config.source = MySource.new
end
```

When the implementation is an autoloaded constant, assign it inside a `to_prepare` block so each reload picks up the new class. Keep the block inside `configure` so `config` stays in scope:

```ruby
Audiences.configure do |config|
  Rails.application.config.to_prepare do
    config.source = MySource.new
  end
end
```

##### The port

The port is the set of methods Audiences calls on `Audiences.source`. An adapter implements them: `Audiences::Sources::Legacy` is the default adapter, and a host application can supply its own.

| Method | Arguments | Returns |
| --- | --- | --- |
| `fetch` | `resource_type:`, `query:`, `start_index:`, `count:` (each a `String` or `nil`) | A collection `render json:` can serialize. See the `#fetch` contract below. |
| `groups_of` | `criterion`, an `Audiences::Criterion` | An `Enumerable` of the criterion's groups. Each group must respond to `resource_type`. |
| `users_matching` | `groups:`, an `Array` of groups (never empty) | An `ActiveRecord::Relation` of the users who belong to at least one group of each resource type among `groups`. |
| `all_users` | none | An `ActiveRecord::Relation` of every user. |
| `extra_users_of` | `context`, an `Audiences::Context` | An `ActiveRecord::Relation` of the context's extra users, inactive ones included. |
| `find_users` | `references`, an `Array` of `Hash`es with `id` and/or `externalId` (string or symbol keys) | The users matching any reference, as an `ActiveRecord::Relation` where the adapter can. An empty `Array` returns no users. |
| `present` | `records`, a relation or `Array` of users or groups | An `Array` of `Hash`es in the client contract shape. |
| `search_users` | `users`, a relation, and `query`, a `String` | `users` narrowed by `query`, as a relation. |
| `identity_keys` | `users`, a relation | An `Array` of identity-key values. |

Details an adapter has to follow:

- `groups_of` and `extra_users_of` find their records from the stored references (see [Stored references](#stored-references)): `criterion.source_group_ids` and `context.source_user_ids`.
- `users_matching` receives groups already loaded into an `Array`. Audiences never calls it with no groups; it uses `all_users.none` instead. The relation it returns has no default users scope; Audiences applies that.
- The stored ids are strings, and the adapter derives `resource_type` itself from its own group records. Audiences stores no resource type for a reference.
- `present` is one batch call, so an adapter can preload once for the whole collection. The `id` of every element must be an integer or an integer string (`42` or `"42"`). Group elements have `id`, `externalId` and `displayName`. `Legacy` limits user elements to the keys in `exposed_user_attributes`; whether another adapter honors that setting is up to the adapter.
- `find_users` is a lookup for consumers, for example an endpoint that adds extra users by reference. The adapter matches `id` and `externalId` itself. Audiences does not call it when saving a context.
- `Audiences.update` reads each `extra_users` entry as `{ "id" => <scim_id>, "externalId" => ... }`, so its payload has to be in the client contract shape. A consumer passes `Audiences.source.present(records)`, not `records.as_json`: for an adapter other than `Legacy`, a record's own `as_json` can put the database primary key in `"id"`.
- `search_users` must return a relation, because Audiences applies `limit`, `offset` and `count` to the result.
- `identity_keys` returns exactly one key per user, in the order of the relation it was given, with `nil` for a user that has none. An adapter that removes duplicates, drops `nil` or reorders makes the `has_audience` readers stop lining up with the users, and Audiences cannot cheaply detect that.

Audiences applies `Audiences.default_users_scope` to the user relation an adapter returns, and combines the criteria of a context with ActiveRecord's `.or`. Every user relation an adapter returns for one context therefore has to be an `ActiveRecord::Relation` of the same model. `#fetch` is the only method that applies the default scopes itself (both of them, see [Scopes](#scopes)). No other method applies the groups scope.

Audiences calls the port from `Context#users`, `#count`, `#extra_users` and `#as_json`, from `Criterion#as_json`, from the users search behind `GET /:key/users`, and from the `has_audience` readers.

##### The `#fetch` contract

```ruby
def fetch(resource_type:, query:, start_index:, count:)
```

All four arguments come straight from request params with no casting or defaulting, so each one is a `String` or `nil`.

- `resource_type` is the wildcard path segment: `"Users"`, `"Groups"`, `"Departments"`, and so on. The segment is optional in the route, so `GET /scim` passes `nil`.
- `query` is a substring to match against the display name. `nil` applies no filter.
- `start_index` is an offset and `count` is a limit, both as strings such as `"2"`. `nil` means no restriction, so omitting `count` returns the whole catalogue. An adapter doing arithmetic on either has to call `to_i` first.

##### The return contract (`#fetch` and `#present`)

`#fetch` returns a collection `render json:` can serialize: an `ActiveRecord::Relation`, serialized through each record's `as_json`, or an array of hashes rendered as given. `#present` returns the same element shapes, always as an `Array` of `Hash`es.

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

That payload is then filtered to the keys in `exposed_user_attributes`, which holds string keys and defaults to `id`, `externalId`, `displayName`, and `photos`. The filter drops any configured key the payload lacks, so listing `title`, `groups`, or the extension URN only works if the adapter emits them. Legacy builds all of this in `ExternalUser#as_scim`.

##### Scopes

Legacy applies the configured scopes inside `#fetch`. The controller does not:

```ruby
if resource_type == "Users"
  ExternalUser.instance_exec(&Audiences.default_users_scope)
else
  Group.where(resource_type: resource_type).instance_exec(&Audiences.default_groups_scope)
end
```

Both default to `-> { active }`. A replacement adapter's `#fetch` has to apply them itself; skipping them serves inactive records and bypasses whatever membership restriction the application configured.

What an adapter has to support:

- **Users scope.** Audiences runs `default_users_scope` on every user relation the adapter returns from `all_users`, `users_matching` and `extra_users_of`, so the adapter does not apply it for those methods. The default is `-> { active }`, which calls `active` on the adapter's user model. Either define `active` on that model, or set `default_users_scope` to a proc the model supports, such as `-> { all }`. In `#fetch`, the adapter applies the users scope itself.
- **Groups scope.** Audiences never runs `default_groups_scope`. The adapter's `#fetch` applies it itself, and `groups_of` returns groups with no scope applied.

Each proc is `instance_exec`'d against whatever relation the calling code holds, and there is one `default_users_scope` for the whole gem. A proc may therefore only call scopes that exist on every model it reaches, and an adapter backed by another model needs equivalent scopes defined there.

##### Stored references

Saving a context stores which groups and extra users it refers to, in two nullable string columns, each with a plain index and no foreign key:

| Column | Holds |
| --- | --- |
| `audiences_criterion_groups.source_group_id` | The id of a criterion's group, as a string. |
| `audiences_context_extra_users.source_user_id` | The id of an extra user, as a string. |

They sit beside the legacy foreign keys (`group_id` and `external_user_id`), which are still written on every save. A `before_save` callback copies the legacy record's `scim_id` into the new column, so an adapter has to be able to find its own records by that `scim_id` value, as a string. Rows saved before the columns were added hold `NULL`, and there is no backfill, so an adapter other than `Legacy` sees only rows saved afterwards.

Saving a context (`Audiences.update`) still resolves each picked group and user in Audiences' own tables (`Group` and `ExternalUser`), whatever the adapter. A host therefore keeps those tables filled until a later release replaces this lookup with one through the adapter.

#### Adding Audiences to a Model

A model object can contain multiple audience contexts using the `has_audience` module helper, which is added to ActiveRecord automatically when configured:

```ruby
Audiences.configure do |config|
  config.identity_class = "User"
  config.identity_key = "login"
end
```

The `identity_class` represents the SCIM user within the app domain, and the `identity_key` maps directly to the SCIM User's `externalId`.

`Context#users` returns the adapter's own records, and Audiences promises no attributes on them (for example, no `user_id`). The default `Legacy` adapter returns `ExternalUser` records, which have `user_id`, but a replacement adapter's records may not. To get identity keys, call `Audiences.source.identity_keys(context.users)`; that is the supported way, and it works with any adapter.

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
