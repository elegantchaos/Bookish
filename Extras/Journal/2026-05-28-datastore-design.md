# 2026-05-28 Datastore Design

## Context

Promoted the second database proposal into the canonical datastore direction for Bookish.

## Notes

- The datastore design uses write-once mutation records, CKSyncEngine, raw SQLite, a mutation store/service, and a projected record store/service.
- Application-level catalogue concepts are now separated from persistence mechanics.
- Data view design is separated from both the catalogue model and datastore implementation details.
- The original database design contained useful catalogue concepts around records, entities, links, and lists, but its Core Data-specific implementation details are superseded.
- The first database proposal contributed useful implementation reminders around small APIs, interchange, and tests.

## Output

- Renamed `Extras/Documentation/Database Proposal 2.md` to `Extras/Documentation/Datastore Design.md`.
- Replaced `Extras/Documentation/Database.md` with `Extras/Documentation/Catalogue Model.md`.
- Added `Extras/Documentation/Datastore Implementation.md`.
- Added `Extras/Documentation/Data View Design.md`.

## Follow-Up

- Decide the record service observation model for SwiftUI.
- Define the concrete mutation and record store SQLite schemas.
- Define list ordering, CloudKit mapping, conflict UI, blob upload state, and interchange/export shape.
