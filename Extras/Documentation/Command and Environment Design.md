# Command and Environment Design

Bookish uses `BookishEngine` as the application composition root and command
centre. It owns service lifecycles and is the only object that commands use as
their concrete centre. SwiftUI receives a narrow `BookishCommander` façade
instead of the engine itself.

## Responsibilities

The engine has two distinct roles in the application:

- It executes commands as their concrete command centre.
- It owns the services that the application injects into SwiftUI.

Views receive `BookishCommander` through the SwiftUI environment so they can
use command helpers such as `button`, `toolbarItem`, and
`performWithoutWaiting`. The façade holds the engine privately and does not
expose command-provider APIs. Views therefore cannot reach services through
their command dependency.

```text
SwiftUI view
    │
    ├── reads observable state
    │
    └── dispatches command through BookishCommander
            │
            └── BookishEngine
                    │
                    └── narrow provider protocol
                            │
                            └── mutation-capable service
```

## Commands and providers

Each command represents a user or application action. It owns its availability,
validation, and execution. A command is generic over the smallest
`XXXProvider` protocol that supplies the required capability.

The engine conforms to these provider protocols by vending existential service
capabilities while retaining concrete service ownership. A command must not
depend on the whole engine, a broad UI-state coordinator, or an unrelated
service merely because the engine happens to own it.

For example, a command that updates debug-index visibility depends on
`BookishBrowserSettingsProvider`, which vends `BookishBrowserSettings`. It does
not depend on import, storage, record-action, recognition, or navigation
capabilities.

New commands should follow this sequence:

1. Identify the action in user terms.
2. Add the smallest mutation method to the action's service protocol.
3. Add a narrow provider protocol that vends that service.
4. Implement the command against that provider.
5. Dispatch the command from the view through the environment-injected commander.
6. Test the command with a fake provider and fake service.

Command failures dispatched with `performWithoutWaiting` are reported through
the engine's command-failure handling and user-visible status service.

## View rules

Views should read state and dispatch discrete actions through commands. Examples
include selecting navigation destinations, importing a file selected by a system
picker, changing browser debug visibility, marking a record, and adding
recognition candidates.

Toolbar content belongs to the view that owns its context. Workflows offer
their own commands, the active index offers navigation and its configured New
action, and each visible book detail offers commands targeting that book's ID.
The iOS Settings toolbar action opens the app's settings sheet through a
command. Index records declare their creatable kinds in `newRecordTypes`,
separately from the advisory `types` used for presentation.

Direct bindings are a deliberate exception. SwiftUI controls such as `Picker`,
`Toggle`, and `NavigationStack(path:)` need stable bindings and may write their
bound value directly for now. A future command-intercepting binding wrapper may
wrap these bindings to record or dispatch their changes consistently. Until that
exists, do not replace a native binding with an ad-hoc command-backed binding.

Reporting a view-owned loading or picker error through
`BookishStatusService.State.report(error:)` is also an allowed UI reporting
effect. The state projection may expose methods for view-owned presentation
work; it does not expose the command-facing `API`.

## Read services in the environment

The environment injects the command façade and view-facing observable state.
`BookishStatusService` owns a stable nested `State` object, which the environment
injects as `BookishStatusService.State`. Views read its message and import
progress and may report view-owned errors through its method. The service's
command-facing `API` and command-centre `Provider` protocols live in the same
source file as the service. Storage, navigation, presentation, recognition, and
lookup follow the same shape. Record views resolve stored records through
`BookishStorageService.State`, which exposes read-only queries and the record
revision that keys their reload tasks, and resolve layouts and presentations
through `BookishPresentationService.State`. `BookishUIStateService` is still
injected for import review, export, and Settings presentation until it is split.
The engine is not injected into SwiftUI view content.

The façade intentionally exposes only command dispatch and command UI helpers.
Views should report allowed view-owned loading and picker failures through the
environment-injected status state. All domain mutations continue to use
commands, except for the documented direct-binding exception below.

If compile-time prevention of direct mutation becomes necessary, keep mutable
services out of the UI module and inject only read-only state across the module
boundary. Within one Swift module, this policy is expressed through narrow APIs,
commands, review, and tests rather than absolute access control.

## Related documents

- [Project Layout](Project%20Layout.md) describes the command-driven app
  structure.
- [Datastore Implementation](Datastore%20Implementation.md) describes the
  record-service and mutation-service split.
