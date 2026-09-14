# 0006: Use versioned JSON record documents for interchange

- Status: Accepted
- Date: 2026-06-02

## Context

Bookish needs a portable file format for exporting and importing multiple
catalogue records, exchanging files with other processes or applications, and
supporting inspectable fixtures.

## Decision

Bookish interchange files are versioned JSON documents containing materialised
`BookishRecord` snapshots, optional schema customisation, and an optional root
record.

The canonical default schema uses `ℹ` for record identifiers, `©` for record
kinds, and `®` for explicitly tagged record values. A document may override
these reserved keys, and its default record kind, through its schema when
interoperating with a compatible external format.

The format uses concise JSON forms where meaning is unambiguous and explicit
tagged values where it is not—for example, for record links, blobs, deletions,
tombstones, conflicts, and encoded values. The codec converts between the
document representation and the in-memory `BookishRecord` model; JSON shorthand
does not escape into application APIs.

Ordinary interchange represents current record snapshots, not mutation history.
Mutation history may use a separate diagnostic, recovery, or archive format.

## Alternatives considered

Using mutation history as the ordinary import and export format was rejected
because it exposes synchronisation mechanics rather than portable catalogue
content. Source-format-specific exports were rejected as the common contract;
they remain importer concerns. Compact JSON is retained only where unambiguous,
with explicit tagged forms for infrastructure values.

## Consequences

- Users and tools can exchange portable collections of records.
- The file format can evolve independently of persistence and synchronisation.
- External formats convert to and from Bookish interchange at their boundaries.
- The document format requires explicit versioning and compatibility rules.
