# 2026-09-25 Fine-Grained Record Observation (Deferred)

Bookish should work out of the box with at least 100,000 records. Its current
change propagation does not scale to that, and this entry records the problem
and the intended direction. The work is a separate refactor, deferred until the
service refactor described in
[Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md) is
finished.

## Current mechanism

Record data does not reach views as observable state. Views fetch records,
layouts, presentations, and query results with one-shot async calls and keep
the results in `@State`. `BookishStorageService.State.revision`, moved from UI
state in [Record Views Without UI State](2026-09-25-record-views-without-ui-state.md),
is part of every record view's `.task(id:)` key. It is bumped only at the end of
`refreshBrowser()`, so every refresh reloads every visible record view,
whatever changed. Any write path that forgets to call `refreshBrowser()` leaves
views stale.

`BookishDatastore` calls `RecordQueryService.refreshResults()` after every
mutation. Each live `RecordQueryResult` then re-runs its whole query against
the whole store (`JSONRecordStore.records(matching:)` filters and sorts every
record) and compares complete record arrays. Cached results are never released,
so dead queries keep being refreshed. A 10,000-record import into a
100,000-record store is quadratic.

## Intended direction

- A view showing one record observes that record and refreshes only when it
  changes, including when it is deleted.
- A view may depend on several records and observes each of them. Record detail
  depends on its record and on configuration: layout, presentations, kind
  metadata, linked layout items, and query-section definitions. The
  presentation service's state should observe configuration records and publish
  resolved configuration, so views don't refetch it.
- Each view subscribes only to what it renders itself. A record link view
  subscribes to its linked record so its name and icon stay current; the view
  containing the link embeds it and does not subscribe to the link target. List
  rows likewise observe their own records, while the list observes the query
  result's ordered IDs.
- Lists are query-backed. Query results update when their results change and
  publish ordered IDs, not full record arrays.
- A query section's query depends on host values, so the view rebuilds its query
  when the host changes.
- Navigation reconciles selection and the detail path when records are deleted.
- Non-record state, such as the mutation log shown by the debug browser, needs
  its own signal and paging.
- Replacing the store (reset, rebuild, sync) is the only legitimate
  reload-everything event.

## Datastore requirements

- The store reports which records each mutation changed.
- Query results re-evaluate only against changed records and update their
  ordered IDs incrementally.
- Results are released when nothing observes them.
- Local and remote mutations produce the same notifications.
- Bulk work such as imports coalesces notifications per batch.

## Consequences for the service refactor

Step 4 of the service refactor keeps the current `revision` behaviour. The
browser-refresh owner introduced there should expect to shrink once views
observe records and queries directly: `refreshBrowser()` would then only
reconcile navigation and presentation. The observation design should be
recorded as its own decision when this work starts.
