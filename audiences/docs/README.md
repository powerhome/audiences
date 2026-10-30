# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Installation

Requires Ruby 3.1 or newer and Rails 7.1 or newer. Your chosen Rails version may require a newer Ruby.

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

`Audiences.source` is the port for directory reads, membership queries, host-identity values, picked-reference resolution, and user-search filtering. Your application supplies an adapter through `Audiences.config.source`; only the adapter needs to know its storage schema and lookup fields.

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

Set the model class names as strings in an initializer before Audiences models load. Keep those settings outside `to_prepare`. Assign the source inside `to_prepare` so reloads pick up changes to the adapter.

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

##### Host identity values

`identity_values_for(users:)` accepts the already-filtered membership relation and returns an array containing one host-identity lookup value per source user. Preserve the supplied relation's order, repeated values, and any `nil` values; do not broaden the scope or return host records.

The adapter determines how to extract those values. Legacy uses `users.pluck(:user_id)`. Audiences uses the returned values to look up `identity_class` records by `identity_key` in bulk, with ActiveRecord key conversion. The resulting array preserves source order and repeated identities, with `nil` entries for missing host identities.

This operation is used by the generated host-identity helper. Membership queries, external-user helpers, and user search continue to return source records.

##### Reference resolution

- `resolve_criterion_groups(resource_type:, references:)`: find picked groups of the given resource type and return records of `group_model_class`.
- `resolve_extra_users(references:)`: find picked users and return records of `user_model_class`.

`references` contains submitted picker hashes, such as `{ "id" => "group-reference" }` or `{ "externalId" => "external-reference" }`. Treat these identifiers according to your adapter's schema; Audiences does not choose the lookup fields.

Return a collection of matching records, such as a relation or array, not a scalar record or a legacy/configured pair. During dual-write, each adapter receives one submitted reference per call and must resolve exactly one record. Missing or ambiguous matches raise `ActiveRecord::RecordNotFound` before saved selections change.

Do not apply the default active scopes during resolution: existing selection behavior allows inactive records to be picked.

##### User search

`search_users(scope:, query:)` returns an unpaginated user relation filtered from the supplied `scope`. Never restart from all users or widen the audience: the scope may already contain context membership, criterion membership, and application restrictions.

The adapter defines which attributes are searchable. Legacy searches across stored user attributes in its serialized data, not just the display name. Other adapters implement filtering appropriate to their own data.

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

Adapters must apply the configured scopes in `fetch`:

- For user resources, apply `default_users_scope`.
- For group resources, restrict results to the requested resource type and apply `default_groups_scope`.

Both scopes default to `-> { active }`. Respect application overrides so directory results follow the configured eligibility and membership restrictions.

Scope procs must use scopes supported by every model they run against, including the configured source's models and Legacy models while those remain in use.

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

Context-summary JSON currently gets group and extra-user details from the legacy projection. Counts, membership queries, and user-list search use the selected source. Switching sources does not change where those summary details come from.

#### Upgrade an existing legacy-backed installation

1. **Apply the supplied database migrations.** These add `configured_group_id` alongside `group_id` on `audiences_criterion_groups`, and `configured_user_id` alongside `external_user_id` on `audiences_context_extra_users`. Keep the legacy columns.
2. **Deploy the updated gem with the adapter configured, while reads still use Legacy.** Set the backing model classes before the join models load. The selector must send reference-resolution calls to the configured adapter regardless of which source handles reads. Selection saves now write both references automatically.
3. **Populate configured references on existing selections.** For each existing criterion-group or extra-user selection, resolve the corresponding configured record and store its primary key in the new column. Leave the legacy reference unchanged.
4. **Verify the backfill before selecting the new source for reads.** Every existing selection must resolve through either source.

The configured adapter and the built-in Legacy adapter must understand the references submitted by the picker. Keep projection synchronization running throughout this transition so Legacy reads and a code revert remain usable.

Selection writes through `Audiences.update` resolve both sources and save both references unconditionally. The public `extra_users:` argument is unchanged.

Selection updates are atomic: a rejected save leaves the previous selections intact.

If your application uses a temporary read-source selector:

- Select `fetch`, `all_users`, `groups_of`, `users_matching`, `extra_users_of`, `search_users`, and `identity_values_for` according to the read toggle.
- Always delegate `resolve_criterion_groups` and `resolve_extra_users` to the configured adapter, regardless of the toggle.

Read selection never controls dual-write. Notification triggers still originate on the projection; changing the read source does not replace those triggers.

#### Adding Audiences to a Model

A model object can contain multiple audience contexts using the `has_audience` module helper, which is added to ActiveRecord automatically when configured:

```ruby
Audiences.configure do |config|
  config.identity_class = "User"
  config.identity_key = "login"
end
```

`identity_class` is the host application's model returned by the identity helper. `identity_key` is the column on that model matched against `identity_values_for(users:)`; it defaults to `:id` and can be a key such as `login`. These settings are independent of `user_model_class`, which identifies the adapter's membership-source model.

Once configured, add audience contexts to a model:

```ruby
class Survey < ApplicationRecord
  has_audience :responders
  has_audience :supervisors
end
```

`survey.responders_context.users` and `survey.responders_external_users` return source user records. `survey.responders` returns an array of host identities resolved through `identity_class` and `identity_key`.

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
