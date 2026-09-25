# 0014: Structure command capabilities around narrow service providers

- Status: Accepted, partially superseded by [Decision 0022](0022-service-state-api-and-provider-shape.md)
- Date: 2026-09-14

## Context

Bookish commands need focused capabilities rather than broad access to the
application composition root. Services also publish observable state for views.
At present, a view observing a service can see its command-facing API, creating
a risk that it could bypass commands and invoke that API directly.

## Decision

The command centre—currently `BookishEngine`—conforms to narrow provider
protocols. Each provider vends only the service required by a related group of
commands.

Commands depend on the smallest provider protocol that vends their required
service. They use that service’s API to implement their action, rather than
depending on the command centre, another unrelated service, or a broad
application coordinator.

Commands are grouped functionally around the services they require. A service
groups related command capabilities and also publishes the state that views need
to observe.

Views may subscribe to service state, but must dispatch discrete actions through
commands. They must not call command-facing service APIs directly, even where
the current interface technically permits it.

This is presently a convention enforced by API design, review, and tests. The
design should later split each service into a read-only observation interface for
views and a command-facing interface for command implementations. Module
boundaries should then make direct view mutation impossible by construction.

Most services currently live in `BookishApp`. When a feature has a coherent
domain boundary, its service, related commands, and underlying implementation
may move together into a domain-specific package. For example, `BookishRecognition`
may own recognition services, recognition commands, and recognition implementation while
depending only on lower-level packages.

## Alternatives considered

Giving commands the whole command centre, broad application coordinator, or
unrelated services was rejected because it hides dependencies and enlarges test
fixtures. Letting views call services directly is also rejected, although the
current same-module implementation cannot completely prevent it. The planned
read-only view and command-facing service interfaces are retained as the route
to enforce the rule at module boundaries.

## Consequences

- Commands have focused, testable dependencies and use small fake providers.
- Services remain the source of truth for both related actions and observable
  feature state.
- Views retain a clear rule: observe state directly, dispatch actions through
  commands.
- The current same-module design cannot fully prevent direct service mutation;
  the planned read/write interface split is the path to enforcement.
- Feature packages can be extracted without separating commands from the
  services and domain operations they coordinate.
