# Unreleased

# Version 2.0 (2025-08-25)

The all new 2.0 release inverts the SCIM logic, where now Audiences no longer pulls data from SCIM, but rather it will receive and cache SCIM data, allowing for an in database calculation of audiences. This improved process allows audiences to be more independent from SCIM, while still compatible with the protocol.

- Update ExternalUser on membership changeas [#541](https://github.com/powerhome/audiences/pull/541)
- Filter extra_users in context JSON [#540](https://github.com/powerhome/audiences/pull/540)
- Introduce helpful scopes [#538](https://github.com/powerhome/audiences/pull/538)
- Allow inactive groups in criteria [#537](https://github.com/powerhome/audiences/pull/537)
- Allow creating external users and groups with internal and external ids [#536](https://github.com/powerhome/audiences/pull/536)
- Reactive audience recalculation [#535](https://github.com/powerhome/audiences/pull/535)
- match group criteria [#534](https://github.com/powerhome/audiences/pull/534)
- Configurable default user and groups scope [#533](https://github.com/powerhome/audiences/pull/533)
- Default authentication to reject requests [#532](https://github.com/powerhome/audiences/pull/532)
- scim proxy with local data [#531](https://github.com/powerhome/audiences/pull/531)
- Local audience calculations [#530](https://github.com/powerhome/audiences/pull/530)
- Local user and group info updated with TwoPercent [#519](https://github.com/powerhome/audiences/pull/519)

# Version 1.6 (2025-03-19)

- Prepackaged audiences-react in UJS [#510](https://github.com/powerhome/audiences/pull/510)

# Version 1.5.4 (2024-12-19)

- Fix `authenticate` / `authentication` configuration [#481](https://github.com/powerhome/audiences/pull/481)
- Paginage user requests in audiences instead of SCIM [#507](https://github.com/powerhome/audiences/pull/507)

# Version 1.5.3 (2024-12-19)

- Rollback breaking change introduced by 1.5.1 [#479](https://github.com/powerhome/audiences/pull/479)

# Version 1.5.2 (2024-12-19)

- Filter sensitive user data out of user list response [#473](https://github.com/powerhome/audiences/pull/473)

# Version 1.5.1 (2024-12-12)

- Fix SCIM proxy attributes format [#462](https://github.com/powerhome/audiences/pull/462)

# Version 1.5.0 (2024-12-12)

- SCIM proxy will only return data used by the UI [#451](https://github.com/powerhome/audiences/pull/451)

# Version 1.4.0 (2024-11-01)

- Add authentication hooks for Audiences controllers [#438](https://github.com/powerhome/audiences/pull/438)

# Version 1.3.1 (2024-10-11)

- Forward pagination parameters to SCIM on proxy [#397](https://github.com/powerhome/audiences/pull/397)
- Fix security flaw when setting extra users [#398](https://github.com/powerhome/audiences/pull/398)

# Version 1.3.0 (2024-09-03)

- Filter out inactive users by default [#382](https://github.com/powerhome/audiences/pull/382)

# Version 1.2.2 (2024-08-21)

- Permit configured resource attributes [#375](https://github.com/powerhome/audiences/pull/375)

# Version 1.2.1 (2024-08-06)

- Fix audiences URL helpers [#372](https://github.com/powerhome/audiences/pull/372)

# Version 1.2.0 (2024-07-24)

- Add `has_audience` and the ability to attach multiple audiences to the same owner [#363](https://github.com/powerhome/audiences/pull/363)
- Audiences.config/configure helpers [#359](https://github.com/powerhome/audiences/pull/359)
- Adjust user id to SCIM Protocol [#356](https://github.com/powerhome/audiences/pull/356)

# Version 1.1.2 (2024-06-18)

- Ignore empty groups in criterion [#354](https://github.com/powerhome/audiences/pull/354)

# Version 1.1.1 (2024-06-18)

- Fix default resource attributes [#342](https://github.com/powerhome/audiences/pull/342)

# Version 1.1.0 (2024-06-10)

- Bump a number of libraries (see release notes)

# Version 1.0.3 (2024-05-14)

- Fix PostgreSQL compability [#312](https://github.com/powerhome/audiences/pull/312)
- Fix audiences resources pagination [#313](https://github.com/powerhome/audiences/pull/313)

# Version 1.0.2 (2024-04-30)

- Fix mysql2 compability – drop sqlite3 [#292](https://github.com/powerhome/audiences/pull/292)

# Version 1.0.1 (2024-04-25)

- Release build adjustments

# Version 1.0 (2024-04-25)

- Inaugural release of Audiences
