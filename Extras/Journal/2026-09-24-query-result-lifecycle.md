# Query result lifecycle — 2026-09-24

## Finding

Reset and projection rebuild replaced `BookishDatastore`, including its query service. The browser retained a `RecordQueryResult` from the old service, so it displayed stale records until the user changed indexes. Ordinary mutations already refreshed results owned by the current service.

## Work

- Kept the query service and its observable result objects across datastore replacement. The storage service points the query service at the new record store after seeding or replay completes.
- Added refresh versions so an older asynchronous query cannot overwrite a newer result.
- Compared full record arrays in the query-service actor before publishing, keeping the normal equality check off the main actor. Unchanged results retain their revision and do not notify SwiftUI.
- Corrected the reset test to inspect removal of the imported record while preserving expected configuration seeds; added result-lifecycle tests for reset, rebuild, and later mutations.

## Remaining work

- Query refresh still scans every cached query after every mutation. The scaling plan is in [Data View Design](../Documentation/Data%20View%20Design.md#query-refresh-and-scaling).
- The navigation service retains its selected record ID when that record disappears from a live result. Selection reconciliation should follow the result's membership without tying it to a particular command.

## Follow-up — live selection

Navigation now observes its active result and clears the selected record and linked-record path when that record leaves the result. It unsubscribes when the active result changes. Regression tests cover reset, ordinary live result changes, retained selections, and old-result updates. The shared test harness now uses isolated settings suites so parallel tests cannot change each other's starting index.
