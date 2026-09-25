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

## Follow-up — reset display bugs (deferred)

After resetting a store in the app, two display problems appeared:

- The record list for the previously selected index (Lists) kept showing its
  old records after the reset.
- Clicking a sidebar index moved the selection highlight at once, but the bold
  selected-row styling stayed on the previous row for a while.

`resetEmptiesSelectedNonBookIndex` shows the navigation service's selected
result does empty after a reset, so the first problem is in when views update,
not in the services. The sidebar's selection binding only changes once
`SelectRecordIndexCommand` runs, so the second suggests commands waiting behind
slow work. Both may come from query refresh re-running every cached query after
each change. Fixing them is deferred.

An empty catalogue after a reset is expected: reset loads configuration seeds
only, without the sample library.

## Follow-up — mutation order fixed on main

After rebasing onto main with
[Decision 0023](../Decisions/0023-mutation-creation-time-ordering.md), which
gives mutations a precise, strictly increasing creation time, the rebuild test's
known-issue marker was removed and its order checks are strict again. The import
audit decision was renumbered to
[Decision 0024](../Decisions/0024-import-sessions-produce-audit-records.md)
because main had already taken 0023.
