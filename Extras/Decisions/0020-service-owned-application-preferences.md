# 0020: Keep application preference ownership with the service that owns the state

- Status: Accepted
- Date: 2026-09-18

## Context

Bookish application services hold state that may need to survive a relaunch.
Separating a service's state from its corresponding persisted preference adds
coordinators, callbacks, and startup ordering without improving testability
when the preference has one clear owner.

## Decision

An application-defined service that owns a durable internal property may read
and write its typed `AppSettingKey` through an injected `UserDefaults` instance.
The key is declared in `BookishApp/Settings.swift` and is the service's single
source of truth for that durable preference.

Each persistent value has exactly one owning service. Other services and views
must use the owner's state or behaviour; they must not read or write the same
setting independently.

Reusable packages remain storage-agnostic under decision 0018. This policy
applies only to services defined by `BookishApp`.

## Consequences

- Service tests inject an isolated defaults suite and stay deterministic.
- Persistence behaviour remains local to the state it preserves.
- A preference cannot acquire competing writers with divergent fallback rules.
- Cross-service preferences require an explicit owner before implementation.
