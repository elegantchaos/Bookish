# 2026-05-27 Project Layout Review

## Context

Reviewed Bookish against the newer Stack, ActionStatus, and ClockSync projects to document the reusable project layout pattern.

## Findings

- All four projects use a thin app shell plus reusable package code under `Dependencies/`, but Stack and ActionStatus are clearer modern examples.
- ActionStatus provides the strongest command-driven pattern through `Commands`, `CommandsUI`, command provider protocols, and a command centre.
- Stack provides the strongest localisation direction: module-owned string catalogs and generated symbols where possible.
- ActionStatus provides the strongest owned-dependency development pattern through Git submodules under `Dependencies/`.
- ClockSync shows the same package extraction approach in a smaller project with one main reusable package.

## Output

- Added `Extras/Documentation/Project Layout.md`.
- Updated `Extras/Documentation/Specification.md` with Bookish-specific adoption notes.

## Open Questions

- `Sources/` is the standard folder name.
- Root `Package.swift` support should be tooling-managed if needed, probably through `rt`.
- Decide how much of Stack's service-target granularity to adopt.
- Decide whether localisation symbol generation should use an explicit command-line plugin.
