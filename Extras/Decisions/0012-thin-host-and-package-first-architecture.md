# 0012: Use a thin app host and package-first architecture

- Status: Accepted
- Date: 2026-05-27

## Context

Bookish needs clear module boundaries, fast package-level testing and previews,
and a practical way to develop reusable Elegant Chaos libraries alongside the
application without losing their independent ownership and release paths.

## Decision

The Bookish Xcode application target is deliberately thin. It owns product
assembly, platform entry points, entitlements, and shipping-app resources, but
not domain logic, service implementations, persistence models, or reusable UI.

Most functionality lives in local SwiftPM packages under `Dependencies/`.
Packages are introduced where a boundary improves ownership, reuse, testability,
or dependency direction; they are not created merely to move a small number of
files.

Functionality that is not uniquely Bookish may live in separately owned Elegant
Chaos packages. `Commands` and `Logger` are current examples. A Bookish-local
package may later be extracted when it gains a reusable, application-neutral
boundary; `Datastore` is an intended candidate.

Each package’s `Package.swift` declares external Elegant Chaos dependencies with
explicit repository URLs and released version requirements. During coordinated
development, the corresponding locally checked-out Git submodule is added to
the Bookish Xcode workspace on its `integration/bookish` branch. The workspace
then builds against that local package rather than the released version selected
by the manifest.

This local override is intentional: it allows dependency changes to be developed
and validated in Bookish while each package retains its independent repository,
history, and release identity. It is also a deliberate compromise. Until those
changes are integrated upstream and released, a package may not build in
isolation through command-line SwiftPM outside the Bookish workspace.

Changes to external packages must therefore be periodically integrated into
their mainlines and released with proper version tags. Bookish must then update
its manifest requirements to those releases, restoring independent package
builds outside Xcode. This local-development pattern should be revisited if a
better mechanism emerges.

## Alternatives considered

A feature-heavy Xcode host was rejected because it weakens package boundaries,
testing, previews, and reuse. A hand-maintained root package is not the default;
tooling may create an aggregate package when required. Treating every package as
either permanently internal or immediately external was rejected in favour of
extracting packages only after they establish a reusable boundary. Workspace
submodule overrides are retained as a temporary co-development compromise, not
as a replacement for released versioned dependencies.

## Consequences

- Most Bookish behavior can be built and tested outside the Xcode app host.
- Bookish-local and Elegant Chaos package boundaries remain explicit.
- Xcode workspace builds may intentionally differ from standalone SwiftPM builds
  during shared-package integration work.
- External-module releases and Bookish manifest updates are required maintenance,
  not optional cleanup.
- Git submodules add operational overhead, so they are reserved for owned
  packages that need active local co-development.
