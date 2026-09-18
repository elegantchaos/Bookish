# 0018: Keep user configuration out of reusable packages

- Status: Accepted
- Date: 2026-09-18

## Context

Reusable packages need configuration such as enabled features, user choices,
and credentials. Allowing a package to read or write that configuration
directly couples otherwise reusable code to a storage implementation and makes
its behaviour depend on ambient user state.

The application is the place that knows which user owns the configuration, how
it is stored, and how it is presented for editing.

## Decision

Reusable packages do not own the storage or presentation of user preferences,
configuration, or credentials. They do not depend on a concrete configuration
store merely to retrieve user-controlled values.

`BookishApp` is the composition root. It retrieves and stores user preferences
and credentials, presents any settings UI, decides which provider instances are
enabled, and passes the necessary configuration to package types through
initializers or narrow injected protocols.

Where configuration changes available behaviour, packages expose an explicit
runtime reconfiguration boundary. The application can then add, replace, or
remove configured components without restarting. A package may replace a
configured instance or reconfigure an existing one, provided the resulting
behaviour remains explicit and testable.

## Alternatives considered

Letting each package access configuration storage directly was rejected because
it introduces ambient storage dependencies, duplicates settings UI and policy,
and makes runtime reconfiguration unnecessarily awkward. Giving packages a
general-purpose application configuration service was rejected because it would
hide dependencies behind a broad interface rather than make them explicit at
construction.

## Consequences

- Packages receive user-controlled values through explicit dependencies.
- Storage and settings UI are tested separately from package behaviour, while
  package tests inject fixed configuration without accessing user storage.
- Changing configuration causes the application to update the associated
  components through their reconfiguration boundary.
- Credentials must never be persisted in package configuration, logs, fixtures,
  or source control.
