# 2026-09-26 Query Result Lifetime and Filter Refinement

Addresses P1 from the [Code Review](../Documentation/Code%20Review.md): filter
keystrokes and query sections created `RecordQueryResult`s that the query
service kept for ever, and every mutation re-ran all of them against the whole
store.

## Requirements

- Only queries deliberately stored in records (indexes, presentations, query
  sections) create query results.
- Nothing keeps a result once its clients have finished with it.
- Filters fit the UI: debounced, working from the underlying result rather than
  a new query, and changed in place rather than recreated per keystroke.

## Changes

- `DefaultRecordQueryService` holds results weakly and discards released ones
  before each lookup and refresh. The query sits beside each weak reference, so
  lookups no longer hop to the main actor once per cached result.
- `RecordQueryResult` has an optional `refinement` predicate. The service keeps
  each live result's unrefined records on its actor; `refine(_:with:)` narrows
  them in place without reading the store, and mutations refresh the unrefined
  records and re-apply the refinement. Results are shared only when both query
  and refinement are equal.
- Navigation refines the selected index's result with the name filter instead
  of asking for a filtered query. `RecordQuery.filteringNames(containing:)` and
  `RecordQueryResult.matches(_:)` were removed.
- `RecordIndexView` binds `.searchable` to view `@State` and sends
  `SetRecordNameFilterCommand` from a `.task(id:)` after a 250 ms pause (at once
  when cleared). This also resolves the command-backed text binding in review
  item U1. The field copies back filter changes made elsewhere, such as record
  creation clearing the filter, but not the view's own, so it can't revert
  mid-typing.
- A filter that hides the selected record moves the selection to the first
  visible record, as before; a deletion still clears it.

## Approaches

An in-memory filter in navigation state was implemented first. It met the
requirements but moved away from
[Fine-Grained Record Observation](2026-09-25-fine-grained-record-observation.md):
it depended on results publishing full records, and re-filtered on the main
actor. Moving the filter into the datastore as a refinement keeps the work off
the main actor and puts it where incremental re-evaluation will later happen.

## Remaining

- Each live result still re-runs its whole query after every mutation; there
  are now only as many as clients hold.
- `RecordQuerySectionView` still reloads on `storage.revision` (review P2).
- Sharing means a refinement applies to every holder of that result. Navigation
  is the only client that refines today.
