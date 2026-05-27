# 2026-05-27 Modernisation Specification

## Context

Started the modernisation planning work by drafting a compact high-level specification for Bookish.

## Notes

- Current project evidence shows a Swift/SwiftUI book cataloguing app split into BookishApp, BookishCore, BookishImporter, and BookishCleanup packages.
- Existing documentation describes a flexible record/link/property model backed by legacy Core Data entities.
- Project rules now identify Swift 6, SwiftUI, and a planned move from Core Data to SwiftData as the direction for the new iteration.

## Output

- Added `Extras/Documentation/Specification.md`.

## Open Questions

- Confirm primary platforms for the modernised version.
- Decide the first supported legacy import formats.
- Decide whether sync is CloudKit-first, local-first, or provider-neutral.
