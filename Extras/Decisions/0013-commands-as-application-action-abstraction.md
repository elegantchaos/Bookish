# 0013: Use Commands as the application action abstraction

- Status: Accepted
- Date: 2026-05-27

## Context

Bookish actions may be initiated from SwiftUI controls, menus, toolbars,
keyboard shortcuts, imports, automation, or future external integrations.
Duplicating action logic and availability rules across those entry points would
create inconsistent behaviour and obscure side effects.

## Decision

Bookish uses the Elegant Chaos `Commands` package and its command abstraction as
the basis for application actions.

A command represents a discrete business, operational, or user-initiated action
independently from the interface that invokes it. It owns its action identity,
availability, validation, and execution. Commands depend on focused provider
protocols and call the services that own the underlying capability.

Commands are also the application action-history boundary. State-changing
commands must have explicit undo/redo semantics: they either provide the
information needed to reverse and replay their effect, or deliberately declare
why the action cannot be undone. This gives the app one consistent mechanism for
comprehensive undo and redo rather than separate history implementations for
each interface.

Commands are also the future action-metering boundary. A micropayments system may
associate charges with particular successful commands, supporting pricing per
action rather than a fixed purchase or subscription. No payment policy or
provider is part of this decision; any future billing integration must remain an
adapter around command execution rather than being embedded in business logic.

Analytics may likewise observe command execution through this boundary,
recording action identities and outcomes subject to a separate analytics and
privacy policy. Analytics must not duplicate command behaviour or become a
requirement for command execution.

User-interface and integration layers project existing commands into their own
surfaces. These include buttons, menu items, toolbar controls, keyboard
shortcuts, and importer flows. Future adapters may expose the same commands
through App Intents, AppleScript, MCP, or a command-line application.

An adapter must not recreate a command’s business rules, durable mutation logic,
or undo/redo behaviour. It translates its input into a command invocation and
presents the command’s availability, progress, and outcome in a form suitable
for that surface.

## Alternatives considered

Implementing the same action independently in each user interface, automation,
or integration surface was rejected because validation, side effects, and
undo/redo would drift. Separate history, billing, or analytics mechanisms per
surface were likewise rejected; those concerns attach to command execution as
adapters and do not become command business logic.

## Consequences

- One action has consistent validation, execution, and undo/redo behaviour
  across multiple entry points.
- Commands can be tested independently of SwiftUI and external integrations.
- New automation or extension surfaces can reuse existing application actions.
- A future per-action pricing model can attach metering to existing action
  identities without coupling payment code to each user interface.
- Analytics can consistently observe action outcomes without duplicating
  application behaviour.
- Provider protocols and command APIs become deliberate application-extension
  contracts.
