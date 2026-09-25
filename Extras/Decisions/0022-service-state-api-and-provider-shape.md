# 0022: Separate service state, API, and provider surfaces

- Status: Proposed
- Date: 2026-09-25

## Context

Bookish services currently mix observable properties, view-facing methods, and
command-facing operations on the same concrete type. Some service classes
implement several protocols, while related API and provider declarations are
spread across files. A view that observes a service can consequently reach
operations intended for commands.

[Decision 0001](0001-engine-command-boundary.md) established the engine as the
command centre, the commander as the view's command boundary, and a temporary
direct-binding exception. [Decision 0013](0013-commands-as-application-action-abstraction.md)
established commands as the boundary for application actions and undo history.
[Decision 0014](0014-narrow-command-providers-and-services.md) established narrow
service providers and anticipated a separate view surface. This decision
specifies that separation.

## Decision

Each application service is named `BookishXXXService`. Its source file also
declares its related nested types:

```swift
@MainActor
final class BookishXXXService {
  @MainActor @Observable
  final class State {
    // View-facing properties, bindings, and UI wiring methods.
  }

  @MainActor
  protocol API {
    // Operations needed by commands.
  }

  @MainActor
  protocol Provider: CommandCentre {
    var xxxService: any API { get }
  }

  let state: State
}
```

This is a shape, not a requirement for empty types. A service without
view-facing state needs no `State`. A service without command operations needs
no empty `API` or `Provider`. These three types are nested inside the service
and therefore defined in its source file. Other types follow the normal
one-type-per-file convention and live outside `Services/`; their folder
organisation is outside this decision's scope. The `Services/` folder contains
only service source files.

The service owns its stable state projection and implements its own `API`.
Service classes do not implement several unrelated capability protocols. The
engine owns the concrete services and conforms to each applicable nested
`Provider`, vending only that service's `API` to commands. Commands depend on
the smallest provider they need. Service collaboration may use a narrow API
dependency without giving views that dependency.

SwiftUI receives the `State` projection through the environment, using its
exact type. The projection is observable; the whole service need not be.
Views may read its properties and use its bindings. It may also contain
methods for view-owned presentation or internal UI wiring, such as reporting
an error encountered while loading view content. Such methods do not perform
domain actions. User-initiated domain actions go through `BookishCommander`
and commands, so their execution and undo semantics remain in one place.
Views do not receive the concrete service or its command-facing `API` through
the environment.

## Alternatives considered

Injecting the whole service into SwiftUI retains a route to its command API.
Putting every user-interface effect behind a command would create commands
for presentation-only work that has no meaningful undo or action history.
Keeping API and provider protocols outside their service types makes a service's
boundary harder to inspect. A shared generic service base or protocol is
deferred until repeated concrete machinery makes its value clear.

## Consequences

- Service implementations, command dependencies, and view observation have
  distinct surfaces that can be reviewed independently.
- View-facing state can expose tightly scoped UI methods without widening the
  command API or creating artificial commands.
- Service migrations update environment injection and narrow command providers
  together; existing services can be migrated one at a time.
- This proposal does not yet change the status or wording of earlier decisions.
  Their relationship can be settled after the service migration is reviewed.
