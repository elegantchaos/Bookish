# Command and Environment Design

Bookish uses `BookishEngine` as the application composition root and command
centre. It owns service lifecycles, injects the command centre into SwiftUI, and
is the only object that commands use as their concrete centre.

## Responsibilities

The engine has two distinct roles in a view:

- It is the **commander** that executes commands.
- It is not the preferred source of mutable service APIs for a view.

Views currently receive the engine through the SwiftUI environment so they can
use command helpers such as `button`, `toolbarItem`, and
`performWithoutWaiting`. This is intentional. It does not mean that a view
should directly call a service mutation method reachable through the engine.

```text
SwiftUI view
    │
    ├── reads observable state
    │
    └── dispatches command through BookishEngine
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
5. Dispatch the command from the view through the environment-injected engine.
6. Test the command with a fake provider and fake service.

Command failures dispatched with `performWithoutWaiting` are reported through
the engine's command-failure handling and user-visible status service.

## View rules

Views should read state and dispatch discrete actions through commands. Examples
include selecting navigation destinations, importing a file selected by a system
picker, changing browser debug visibility, marking a record, and adding
recognition candidates.

Direct bindings are a deliberate exception. SwiftUI controls such as `Picker`,
`Toggle`, and `NavigationStack(path:)` need stable bindings and may write their
bound value directly for now. A future command-intercepting binding wrapper may
wrap these bindings to record or dispatch their changes consistently. Until that
exists, do not replace a native binding with an ad-hoc command-backed binding.

Reporting a view-owned loading or picker error through the status service is
also an allowed UI reporting effect, rather than a domain command.

## Read services in the environment

The current environment injects the engine so views can issue commands. Future
work may also inject individual read-only observable state or service objects.
Those read surfaces should expose properties and queries needed for rendering,
but not mutation methods. The engine remains in the environment as commander;
read-service injection complements it rather than replacing it.

If compile-time prevention of direct mutation becomes necessary, keep mutable
services out of the UI module and inject only read-only state across the module
boundary. Within one Swift module, this policy is expressed through narrow APIs,
commands, review, and tests rather than absolute access control.

## Related documents

- [Project Layout](Project%20Layout.md) describes the command-driven app
  structure.
- [Datastore Implementation](Datastore%20Implementation.md) describes the
  record-service and mutation-service split.
