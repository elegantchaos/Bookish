# Record Query Service

Added the first datastore-level record query service.

## Shape

- `RecordQuery` combines a `RecordPredicate` with an ordered list of `RecordSortDescriptor` values.
- `RecordStore` and `RecordService` can return records matching a full query, not just identifiers matching a predicate.
- `RecordQueryResult` is `@Observable` and holds an ordered list of materialised records for direct SwiftUI integration.
- `DefaultRecordQueryService` caches equivalent query results and refreshes the shared result instance.
- `BookishDatastore` owns a query service and wires mutation projection changes into `refreshResults()`.

## Supported Cases

- Basic kind indexes can be represented with `.kind("book")`, `.kind("person")`, and related predicates.
- Relationship-based indexes can use `.propertyContains(...)` to match record links inside list properties such as `authors`.
- UI sorting controls can map onto `RecordSortDescriptor` values, including property-based sorting.
- Record detail sections such as books by an author can be represented as an `.and` query combining kind and list-reference predicates.

## Browser Integration

- The top-level browser is backed by stored records of kind `index`.
- Each `index` record stores a `label`, `debugOnly`, `layout`, `position`, and encoded `RecordQuery`.
- The harness seeds `All Records`, standard kind indexes, and an `Indexes` entry from bundled interchange resources.
- The split-view top-level list and content list now read from observable query results.
- Stored index queries use stable string sort-direction coding; an invalid query leaves the selected content empty instead of silently falling back to all records.
- The metadata seed intentionally has `All Records` as the catch-all entry and no separate `Records` entry, because no application records use kind `record`.
- Standard kind indexes have `debugOnly: false` and appear in the normal top-level browser. `All Records`, `Layouts`, and `Indexes` have `debugOnly: true`; they are included by debug builds and hidden by release builds. Each harness stores `defaultShowsDebugIndexes` as an explicit, injectable dependency, ready to be supplied by a future user setting.

## Seed Resources

- The harness checks for records of kind `seedMarker` to determine whether first-run seeding has happened.
- `MetadataSeed.bookish.json` contains metadata records such as browser indexes and layouts.
- `SampleSeed.bookish.json` contains first-run sample data.
- Application loading imports metadata every time; first-run seeding additionally imports sample resources, then writes the seed marker.
- Reset clears records and mutations, imports only metadata, then writes a fresh seed marker.
- Standard metadata includes an `All Fields` layout whose `fields` list contains only the `*` token, which expands to every record property not already handled explicitly.

## Limits

- The JSON implementation still filters and sorts from the in-memory materialised projection.
- Query-result caching is service-local and equality-based; there is no eviction policy yet.
- If a selected `index` record's encoded query is edited in place, the selected content result is refreshed the next time the harness refreshes or the index is reselected.
