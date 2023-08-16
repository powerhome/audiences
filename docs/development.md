# Development guide

## Full stack w/ Docker

To start up the development environment with the entire stack, just use the docker compose config at the root of this repo:

```bash
docker compose up -d
```

To watch the logs:

```bash
docker compose logs -f <service>
```

This should get the following services up and running:

- Dummy App server
- Dummy App vite dev server
- Package vite build watcher
- SCIM Stub service

To access the dummy app go to http://localhost:3000.

## Individual builders

### `audiences-react`

To work on `audiences-react`, though, you also have the option to start `yarn dev` from `audiences-react`, which will allow you to rapidly make changes to the UI with hot module reload. Check out the [README from `audiences-react`](../audiences-react/docs/README.md).

### `audiences`

The easiest way to get up and running with the dummy app, if you're working on the backend pieces, is to use the full stack development environment with docker.

You can, though, run specs by running `rake`'s default target from the `audiences` directory.
