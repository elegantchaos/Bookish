# 0007: Preserve imported source snapshots in originalData

- Status: Accepted
- Date: 2026-09-05

## Context

An importer necessarily interprets an external source into Bookish records. That
interpretation may improve over time, and source fields that are not useful today
may support better enrichment, diagnosis, or migration later.

## Decision

When an importer creates or updates a Bookish record from external source data,
it preserves the accepted source snapshot in the record’s `originalData`
property as deterministic encoded data, alongside the interpreted Bookish
properties.

`originalData` is the single source-snapshot preservation mechanism. Importers
must not also create parallel `original.*` properties. Presentation layouts
normally exclude `originalData`, while advanced tools may inspect it when needed.

The snapshot records what the importer accepted from the source; it does not
replace the interpreted Bookish properties as the application’s current
catalogue model.

## Alternatives considered

Discarding accepted source data after interpretation was rejected because later
importer improvements would require the original export again. Parallel
`original.*` properties were also rejected because they duplicate preservation
mechanisms and make provenance harder to discover.

## Consequences

- Later importer revisions can mine preserved source data without requiring the
  original export file.
- Diagnostics can compare current interpretation with the imported source.
- Standard record views remain focused on interpreted catalogue data.
- Importers must define deterministic, safe encodings for retained source data.
