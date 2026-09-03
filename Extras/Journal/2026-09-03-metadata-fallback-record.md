# Metadata Fallback Record

Started the metadata record implementation by seeding the universal fallback record.

## Implementation

- Added `BookishRecordKind.metadata` and `BookishRecordKey.presentation`.
- Added `BookishPropertyPresentation` with optional `icon`, `label`, and `viewer` fields.
- Added `BookishRecordValue.presentation` for typed property-presentation maps instead of storing presentation metadata as an opaque encoded payload.
- Added interchange support for tagged presentation values using `_rv: "presentation"` and a `properties` map.
- Seeded `metadata.type.*` as the fallback metadata record with generic presentation entries for common fields.
- Included metadata records in stale seeded-metadata pruning so bundled metadata remains authoritative across launches.

## Presentation Use

- `BookishHarness` resolves `metadata.type.<kind>` before falling back to `metadata.type.*`.
- `BookishRecordPresentation` applies each field's metadata label and SF Symbol icon.
- The record list and detail views load and pass the matching metadata record, while fields without metadata retain their derived label and text presentation.
- Deferred viewer-factory materialisation: the current change intentionally keeps every value on the existing text path.

## Canonical Record Names

- `name` is now the sole persisted display identity for every Bookish record; `title` and index `label` are no longer part of the Bookish record schema.
- Layouts, indexes, metadata, seed markers, sample books, query sorts, and their internal presentation APIs use `name`.
- Delicious Library remains an external `title`-based source format. Its importer reads that source field and maps it to Bookish `name` at the import boundary.

## Notes

The planned fallback ID `metadata.type.*` conflicted with the interchange ID grammar, so the codec now permits `*` after the leading identifier character. This keeps `record` available as a real record kind rather than overloading it as a fallback sentinel.
