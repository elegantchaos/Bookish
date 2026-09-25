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

### Creation

- The import workflow creates the import record after the user confirms the
  import, from the resolved outcome, and writes it with the imported records.
  Importers do not create it, so every current and future source gets the same
  record without source-specific code.
- An import session that changes nothing writes no import record.
- Each import record has its own identity, so every import session produces a
  distinct record. Users do not create import records by hand.

### Content

- Import records have their own record kind, `import`. They are not lists, so
  they are not mistaken for user-managed collections and can have their own
  presentation.
- An import record carries a name identifying the source and time, the source
  identifier, and the date and time the import was applied.
- It links every catalogue record the import touched, grouped by treatment, with
  one plain record-link list per treatment:
  - `importAdded`: records the import added;
  - `importReplaced`: existing records the import overwrote;
  - `importKept`: existing records kept instead of the imported version;
  - `importMatched`: existing records linked in place of matching imported
    records.
- Records the user skipped are not included, and empty treatments are omitted.

### Viewing

- The catalogue has an Imports index, alongside the other library indexes,
  listing import records newest first.
- Import records have their own layout and presentation, showing the source and
  date, then each treatment as a labelled list of links to the affected
  records.

## Alternatives considered

- **Importer-created summary lists.** Rejected: the importer only knows the
  candidates, not the user's choices, and a fixed identity collides on repeat
  imports.
- **Import records as `list` records.** Rejected: they would appear among
  user-managed lists and share the list layout, which has no place for
  treatments.
- **Relationship records for each audited entry.** Rejected for now: they follow
  the documented pattern for entries with metadata, but add one record per
  touched record. One record-link list per treatment is enough to audit an
  import.

## Consequences

- New importers must not emit list or summary records of their own.
- Import records accumulate in the catalogue, one per import session that
  changed something.
- The `import` kind needs its own metadata, index, layout, and presentation
  configuration.
