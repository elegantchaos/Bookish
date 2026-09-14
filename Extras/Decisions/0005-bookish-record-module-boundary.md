# 0005: Use BookishRecord as the shared record-boundary model

- Status: Accepted
- Date: 2026-06-02

## Context

Bookish modules need to exchange catalogue data without exposing persistence
representations or inheriting the schemas of external sources.

## Decision

`BookishRecord`, `BookishRecordID`, and `BookishRecordValue` are the
storage-neutral in-memory model at Bookish module boundaries.

Importers produce `BookishRecord` graphs. Datastore services expose materialised
`BookishRecord` values. Presentation, cleanup, commands, lookup tools, and tests
use the same model rather than module-private persistence or source-format
types.

## Alternatives considered

Exposing datastore-private records across modules was rejected because it would
couple importers, presentation, cleanup, and tests to one persistence provider.
Passing source-format-specific types between modules was rejected because it
would leak external schemas beyond importer boundaries. File interchange remains
a separate concern, recorded in 0006.

## Consequences

- Modules share one explicit catalogue-data contract.
- Import and persistence implementations remain replaceable.
- External source schemas are translated at importer boundaries.
- `BookishRecord` is distinct from the file format used to serialise records.
