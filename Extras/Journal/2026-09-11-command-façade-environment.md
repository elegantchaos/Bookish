# Command Façade Environment

## Decision

SwiftUI content now receives `BookishCommander` rather than `BookishEngine`.
The façade holds a private weak reference to the engine and forwards only
command dispatch and command UI helpers.

## Consequences

- Commands still use `BookishEngine` as their concrete command centre.
- Views cannot access command-provider properties through their command
  dependency.
- Observable UI services are injected separately for rendering and permitted
  view-owned error reporting.
