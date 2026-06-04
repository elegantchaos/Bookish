# Datastore Prototype Navigation

## Context

The datastore prototype moved record browsing route state out of
`DatastorePrototypeHarness` and into `DatastorePrototypeNavigationService`.
The engine owns the navigation service, injects it into the harness, and exposes
it to SwiftUI with the modern observation environment API.

## Implementation Notes

- The main prototype UI is now a three-pane `NavigationSplitView`.
- The first pane selects the record kind, the second pane lists records of that
  kind, and the third pane shows the selected record detail.
- Navigation commands operate on the navigation service:
  - previous and next record type
  - previous and next record
  - direct navigation to a linked record
- Mutation browsing is debug-only and lives in a second window through
  `DatastorePrototypeMutationDebugView`.
- The main record UI no longer loads mutation history during refresh.
- `BookishRecordView` now exposes raw field values and accepts a custom value
  renderer, allowing the prototype app to render `.record` values as active
  navigation buttons without giving `BookishRecordView` visibility of prototype
  navigation services or commands.

## Follow-Up

- Consider richer record-link labels once the record service has a cheap display
  name lookup for linked IDs.
- Consider UI tests for split-view selection and linked-record navigation once
  the prototype app target has a stable UI-test entry point.
