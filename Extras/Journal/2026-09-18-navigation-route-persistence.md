# Navigation Route Persistence

## Changes

- Added a typed navigation-selection setting that distinguishes workflows from
  library and debug index identifiers.
- `BookishNavigationService` now restores the saved route through injected
  `UserDefaults`, validates saved indexes against the visible indexes, and
  persists its resolved route after selection changes.
- Recorded [decision 0020](../Decisions/0020-service-owned-application-preferences.md):
  an application-defined service may own a typed durable preference through
  injected defaults, and each persistent value has exactly one service owner.

## Validation

- Focused navigation persistence tests cover workflow restoration, index
  restoration, and persistence of the resolved fallback selection.
