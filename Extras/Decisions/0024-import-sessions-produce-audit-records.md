# 0024: Import sessions produce audit records

- Status: Accepted
- Date: 2026-09-25

## Context

Imports can add, replace, or reuse many catalogue records at once. Users need
to see afterwards what an earlier import changed, whichever source it came
from.

The Delicious Library importer used to emit its own list record with a fixed
identifier, containing every book in the source. That list was a proposal like
any other record, so a repeat import offered it as a possible duplicate, and it
described the candidates rather than what the user chose to import. Other
importers produced no such record.

## Decision

Each import session that results in any mutations also writes an import record
describing what changed. The user can view these records to audit previous
imports.

- The import workflow creates the record after the user confirms the import,
  from the resolved outcome. Importers do not create it, so every current and
  future source gets the same record without source-specific code.
- The record describes what the import did to each catalogue record it
  touched, grouped by how it was treated. Records the user skipped are not
  included.
- Each record has its own identity and the time of the import, so every import
  session produces a distinct record.
- An import session that changes nothing writes no import record.

## Alternatives considered

- **Importer-created summary lists.** Rejected: the importer only knows the
  candidates, not the user's choices, and a fixed identity collides on repeat
  imports.
- **Relationship records for each audited entry.** Rejected for now: they follow
  the documented pattern for list entries with metadata, but add one record per
  touched record. One record-link list per treatment is enough to audit an
  import.

## Consequences

- The first implementation stores the import record as a `list` record with an
  `import-<UUID>` identifier, `source`, `importDate`, and one record-link list
  per treatment: `importAdded`, `importReplaced`, `importKept`, and
  `importMatched`.
- New importers must not emit list or summary records of their own.
- Import records accumulate in the catalogue, one per import session that
  changed something.
