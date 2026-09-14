# 0001: Use BookishEngine as the command boundary

- Status: Accepted
- Date: 2026-09-11

## Context

Bookish needs a clear boundary between SwiftUI, application actions, service
lifecycles, and durable mutation capabilities. Injecting the engine directly
into views would expose unrelated services and make command dependencies too
broad.

## Decision

`BookishEngine` is the application composition root and the concrete command
centre. It owns service lifecycles and vends the narrow capabilities required by
commands.

SwiftUI receives `BookishCommander`, which privately delegates command dispatch
to the engine, plus individual observable read services. Views dispatch
discrete domain actions through commands. Each command depends on the smallest
provider protocol that supplies its required mutation-capable service.

Direct native bindings for controls such as `Picker`, `Toggle`, and
`NavigationStack(path:)` remain permitted until a shared command-intercepting
binding abstraction exists.

## Alternatives considered

Injecting `BookishEngine` directly into SwiftUI was rejected because it exposes
unrelated services and broad command capabilities to views. A separate concrete
command centre was superseded when the engine became the lifecycle and command
composition root. Direct bindings remain a temporary, explicit exception rather
than a replacement for command dispatch.

## Consequences

- Command behavior is testable with focused fake providers and services.
- Views cannot reach mutation services merely because the engine owns them.
- The engine remains the intentional lifecycle and command boundary.
- This is an architectural convention within the current module, rather than
  absolute compile-time isolation.
