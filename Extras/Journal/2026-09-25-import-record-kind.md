# 2026-09-25 Import Record Kind

[Decision 0024](../Decisions/0024-import-sessions-produce-audit-records.md) was
revised, before any later work depended on it, to describe how import records
should work rather than how the first implementation stored them. It now calls
for a dedicated `import` kind with its own index, layout, and presentation.

This entry brings the code into line with it, following
[Import Review Lists New Records](2026-09-25-import-review-new-records.md),
which stored import records as `list` records.

- `BookishRecordKind.importRecord` is `"import"`. The Swift name avoids the
  `import` keyword.
- `BookishImportResolution.auditList` became `auditRecord` and produces an
  `import` record. Its properties are unchanged.
- Seeds:
  - `IndexSeed`: an Imports index at position 6, after Lists and outside the
    debug group, sorted by `importDate` descending. It has no
    `newRecordTypes`, so the New menu cannot create import records. The debug
    indexes moved down one position.
  - `LayoutSeed`: `datastore-import-layout` showing name, source, import date,
    then the four treatment lists.
  - `PresentationSeed`: `presentation.type.import` labels the import date and
    shows each treatment as a record link list. Name and source fall back to
    `presentation.type.*`.
  - `MetadataSeed`: `metadata.type.import` links the kind to that presentation.

Existing stores only re-apply `MetadataSeed` and `QuerySectionSeed` when
opened. The index, layout, and presentation reach new or reset stores only, so
an existing catalogue needs either a reset or a migration to show the Imports
index. Import records written as `list` records during earlier testing, and
the old `delicious-import` list, remain as lists.
