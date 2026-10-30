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

#### Configure a source

`Audiences.source` is the port for directory reads, membership queries, picked-reference resolution, and user-search filtering. Your application supplies an adapter through `Audiences.config.source`; only the adapter needs to know its storage schema and lookup fields.

Configure the adapter and the models backing saved group and user references:

```ruby
Audiences.configure do |config|
  config.group_model_class = "DirectoryGroup"
  config.user_model_class = "DirectoryUser"
  Rails.application.config.to_prepare do
    config.source = MySource.new
  end
end
```

Set the model class names as strings before the Audiences join models load. Their associations read configuration in their class bodies, so these settings must not be deferred to `to_prepare`. The source assignment uses `to_prepare` so an autoloaded adapter is refreshed on reload.

`Audiences.config.source` defaults to the transitional `Audiences::Sources::Legacy`, backed by Audiences' `ExternalUser` and `Group` projection. Installing this version requires the adapter and both model settings for dual-write; the earlier fetch-only adapter contract is no longer sufficient.

#### Implement an adapter

Implement all the operations below on one source object. Membership reads and selection writes have different responsibilities: read methods return users or groups, while resolution methods find the records needed to save a selection.

##### Directory reads

`fetch(resource_type:, query:, start_index:, count:)` backs `GET /scim(/*scim_path)`. All four arguments come straight from request params without casting or defaulting, so each is a `String` or `nil`.

- `resource_type` is the wildcard path segment: `"Users"`, `"Groups"`, `"Departments"`, and so on. The segment is optional in the route, so `GET /scim` passes `nil`.
- `query` is a substring to match against the display name. `nil` applies no filter.
- `start_index` is an offset and `count` is a limit, both as strings such as `"2"`. `nil` means no restriction, so omitting `count` returns the whole catalogue. A source doing arithmetic on either has to call `to_i` first.

Return a collection that `render json:` can serialize: a relation of records with suitable `as_json` methods, or an array of hashes. Unlike user search below, `fetch` owns its pagination. See [response serialization](#response-serialization) for the client-facing format.

##### Membership queries

- `all_users`: return the base user relation used by `match_all` and by UsersSearch when no scope is supplied.
- `groups_of(criterion)`: return that criterion's selected groups. A configured adapter reads the configured references from `criterion.criterion_groups`; Legacy reads `criterion.groups`. Group records must expose `resource_type`.
- `users_matching(groups:)`: return users belonging to any selected group within each resource type, and to a selected group in every represented type. Return an empty relation when no groups are supplied.
- `extra_users_of(context)`: return explicitly selected users. A configured adapter reads `configured_user_id` from `context.context_extra_users`; Legacy reads `external_user_id`.

`all_users`, `users_matching`, and `extra_users_of` must return unpaginated `ActiveRecord::Relation` objects on the same user model, not arrays. Audiences combines criteria with `.or` and unions them with extra users, so joins, selected columns, ordering, and other relation options must remain structurally compatible across calls.

`Context#users` and `Criterion#users` apply `default_users_scope` to the resulting relations. These operations query membership; they do not save selections.

##### Reference resolution

- `resolve_criterion_groups(resource_type:, references:)`: find picked groups of the given resource type and return records of `group_model_class`.
- `resolve_extra_users(references:)`: find picked users and return records of `user_model_class`.

`references` contains submitted picker hashes, such as `{ "id" => "group-reference" }` or `{ "externalId" => "external-reference" }`. Treat these identifiers according to your adapter's schema; Audiences does not choose the lookup fields.

Return a collection of matching records, such as a relation or array, not a scalar record or a legacy/configured pair. During dual-write, each adapter receives one submitted reference per call and must resolve exactly one record. Missing or ambiguous matches raise `ActiveRecord::RecordNotFound` before saved selections change.

Do not apply the default active scopes during resolution: existing selection behavior allows inactive records to be picked.

##### User search

`search_users(scope:, query:)` returns an unpaginated user relation filtered from the supplied `scope`. Never restart from all users or widen the audience: the scope may already contain context membership, criterion membership, and application restrictions.

The adapter owns searchable attributes and database-specific SQL. Legacy retains its serialized-`data` search, including PostgreSQL's `CAST(data AS TEXT)` and MySQL's `CAST(data AS CHAR)`. Other adapters can search their own columns without a `data` field or those casts.

UsersSearch owns the total count before pagination, limit, offset, and `{ users:, count: }` response:

```ruby
search = Audiences::UsersSearch.new(
  scope: context.users,
  query: "Jane",
  limit: 20,
  offset: 0
)
search.as_json
```

The default limit is 20 and the default offset is 0. Without an explicit scope, UsersSearch uses `Audiences.source.all_users`; it does not independently apply `default_users_scope`.

#### Scopes and serialization

##### Default scopes

Legacy applies the configured scopes inside `#fetch`. The controller does not:

```ruby
if resource_type == "Users"
  ExternalUser.instance_exec(&Audiences.default_users_scope)
else
  Group.where(resource_type: resource_type).instance_exec(&Audiences.default_groups_scope)
end
```

Both default to `-> { active }`. A replacement source has to apply them itself; skipping them serves inactive records and bypasses whatever membership restriction the application configured.

Each proc is `instance_exec`'d against the calling relation. Membership queries now apply `default_users_scope` to the selected source's user model, not always to `ExternalUser`. During migration, the same proc also reaches legacy records through directory reads or context serialization. It must use scopes supported by every model it reaches.

##### Response serialization

Directory resources other than `"Users"` return elements of this shape:

```json
{ "id": "<group_reference>", "externalId": "<external_reference>", "displayName": "<display_name>" }
```

`id` is the picker reference understood by the adapter, not necessarily its database primary key. Legacy emits its `scim_id`.

Legacy builds a `"Users"` element from stored SCIM data plus these keys derived from group memberships:

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

Legacy filters that payload to `exposed_user_attributes`, which uses string keys and defaults to `id`, `externalId`, `displayName`, and `photos`. Configured keys that the payload lacks are omitted.

Replacement adapters must provide the same client-facing attributes without requiring the same storage schema. Returned user records must serialize appropriately for both directory reads and UsersSearch. The controller does not filter arbitrary adapter results; the adapter owns serialization and attribute exposure.

Current context-summary JSON still renders criterion-group details through `criterion.groups` and extra-user details through `context.extra_users`, both legacy associations. Counts, membership queries, and user-list search use the source. Replacing the source does not replace those summary serializers.

#### Migrate existing audiences

1. Apply the migrations adding `configured_group_id` alongside `group_id` on `audiences_criterion_groups`, and `configured_user_id` alongside `external_user_id` on `audiences_context_extra_users`.
2. Configure the adapter and backing models before enabling the new write path. Both adapters must understand the references submitted by the picker. Keep the existing projection synchronization running.
3. Backfill configured references on existing selections before switching their reads to the new source. The configured associations remain `optional: true` for historical rows; stricter association validation is deferred until after production backfill.

Selection writes through `Audiences.update` resolve both sources and save both references unconditionally. Only the adapters interpret identifiers. There is no separate dual-write switch or identity-key configuration, and the public `extra_users:` argument is unchanged.

Extra-user writes retain existing join rows, delete only removed selections, and insert only additions. A retained row is updated only when its configured reference is missing or different; unchanged selections cause no extra-user join-table writes. Criteria retain their existing replacement behavior. A rejected save rolls back all selection changes.

If your application uses a temporary read-source selector:

- Select `fetch`, `all_users`, `groups_of`, `users_matching`, `extra_users_of`, and `search_users` according to the read toggle.
- Always delegate `resolve_criterion_groups` and `resolve_extra_users` to the configured adapter, regardless of the toggle.

Read selection never controls dual-write. Keeping legacy columns populated allows reverting to the previous Audiences code without repairing newly saved selections. Notification triggers still originate on the projection, so changing the read source is not a reason to remove synchronization or projection callbacks.

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
