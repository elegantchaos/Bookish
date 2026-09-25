# 2026-09-25 Import Review Lists New Records

The Import review screen now lists every record an import would add, not just
possible matches, and is anchored to the top of the workflow pane instead of
floating in the middle.

- `BookishImportChoice` gained `.skip`, which leaves a record out and removes
  links to it from the records that are written: a single link property is
  dropped, and list or conflict values lose that element. A skipped root
  resolves to no root.
- `BookishImportPlanEntry.availableChoices` lists the valid choices for each
  entry. The row popup, bulk actions, and `resolve(choices:)` validation all
  use it, so there is one definition of what is allowed:
  - new records: Add, Skip;
  - same-identifier matches: Keep Existing, Replace Existing;
  - other possible matches: Use Existing (per candidate), Add as New, Skip.
- `defaultChoices` now sets Add for every new record, alongside the existing
  preference for catalogue records on possible matches. A new record without a
  choice still resolves to Add, so callers that pass partial choices keep
  working.
- `BookishImportingService.State.setImportChoice(_:for:)` takes a set of IDs
  and applies the choice only to entries that allow it. It replaces the
  single-ID version.
- The review view shows a "Possible Matches" section followed by a "New
  Records" section, sorted by kind then name. Every row has the same popup on
  the right, and that popup only ever changes its own row.
- Bulk changes act on the list selection, following the platform convention
  that in-row controls affect one row and menus act on the selection:
  - a context menu on the list (`contextMenu(forSelectionType:)`);
  - a "Set Selected To" toolbar menu, with an Edit button on iOS to enter
    multiple selection;
  - Add All and Skip All in the New Records header.
  Both menus offer only the choices that fit at least one selected record.
- Cancel and Import moved out of the toolbar into a bar below the list, with
  Import prominent. `CancelPendingImportCommand` uses the standard cancel
  shortcut (Escape) and `ApplyPendingImportCommand` uses Command-Return.
- Placeholder views in the Import workflow and result screens now fill the
  pane, so they are centred rather than pinned to the leading edge.

## Import audit lists

The branch was renamed from `feature/ios-delicious-library-import` to
`feature/importer-improvements` when the scope grew to cover this.

The Delicious Library importer used to emit a list record with the fixed ID
`delicious-import` that linked every book in the source, and set it as the
import root. A second import proposed the same ID with different contents, and
because the repeat-import check excludes lists, the list came back as a
same-ID possible match. It also listed every candidate, not what the user chose.

Now no importer creates a list. After the user confirms, the importing service
writes an audit list for any source, including interchange and future
importers:

- `resolve(choices:)` records a `BookishImportTreatment` (added, replaced, kept,
  matched) for each record it touched, in plan order. Skipped records and
  supporting records pruned at resolve time are not recorded.
- `BookishImportResolution.auditList(id:name:sourceID:date:)` builds the list
  record, or returns nil when nothing was touched, so an import with every
  record skipped writes no list.
- The list has a unique `import-<UUID>` ID, a name with the source and the
  import date and time, `source`, `importDate`, and one plain record-link list
  per treatment: `importAdded`, `importReplaced`, `importKept`, and
  `importMatched`. Empty categories are omitted. The `import` prefix avoids
  `added`, which books already use for a date.
- `importMatched` links the existing record that stood in for the imported
  one.
- The workflow result's reused count now comes from the kept and matched
  treatments.

Writing the audit list in the same batch as the imported records exposed an
existing datastore problem: mutation dates are encoded as ISO 8601 without
fractional seconds, so mutations from one second reload in UUID order instead of
creation order. `rebuildCommandRebuildsRecordStoreFromMutationHistory` fails
because of it. That fix belongs in its own branch.

An intermediate version used a separate excluded-ID set and a checkbox per new
row. It was replaced before commit by the `.skip` choice, so that every row
expresses its handling through one popup.

Open points:

- Skipping a book from an external importer still prunes its otherwise unused
  author, organisation, and series records at resolve time, even though those
  rows still show Add.
- Each row reads the whole `importChoices` dictionary, so a change invalidates
  every visible row. List laziness keeps this cheap for now, but it does not
  meet the observe-only-what-you-render target for very large imports.
