# Audiences

"Audiences" is a SCIM-integrated notifier for real-time Rails actions based on group changes.

## Installation

1. Follow the [installation instructions](../audiences/docs/README.md#installation) for the audiences gem.
1. Follow the [installation instructions](../audiences-react/docs/README.md#installation) for the `@powerhome/audiences` package for react.

## How does it work

1. User creates a criteria based on SCIM groups;
1. Whenever the group of users matching this criteria changes, a notification is posted to `Audiences::Notifications`;
1. The rails app can react to this change (i.e.: granting or revoking memberships).

## Development

See the [development documentation](./development.md).

## Maintenance 🚧

These packages are maintained by [Power's](https://github.com/powerhome) Heroes for Hire team.

## Contributing 💙

Contributions are welcome! Feel free to [open a ticket](https://github.com/powerhome/power-tools/issues/new) or a [PR](https://github.com/powerhome/power-tools/pulls).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
