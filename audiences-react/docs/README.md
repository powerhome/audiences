# `audiences`

`audiences` is a [SCIM](https://datatracker.ietf.org/doc/html/rfc7644)-integrated UI to create criteria based on SCIM groups and users.

## Usage

### Creating/Managing audiences

The `AudienceEditor` component is the main entry point. It _requires_ an `uri`, which is the audience context URI (see [Managing/Audiences](../../audiences/docs/README.md#creatingmanaging-audiences)) and a SCIM backend URI, which can be the [`Audience::ScimProxy`](../../audiences/docs/README.md#configuring-the-scim-proxy) or the SCIM endpoint – with a properly configured CORS to accept external calls.

With everything in place, the usage should look like this:

```jsx
<AudienceEditor uri={audienceContextUri} scimUri={scimV2Uri} />
```

You can also add arguments to the fetch calls, like headers:

```jsx
<AudienceEditor
  uri={audienceContextUri}
  scimUri={scimV2Uri}
  fetchOptions={{ headers: { Authorization: "Bearer my-token" } }}
/>
```

See [example](../src/example.tsx).

### Peer Dependencies

Audiences assumes three peer dependencies are configured:

- React
- ReactDOM
- playbook-ui

## Installation

```bash
yarn add audiences
```

Or

```bash
npm i -S audiences
```

## Contributing

See [development guide](../../docs/development.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
