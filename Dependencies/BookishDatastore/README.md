# BookishDatastore

`BookishDatastore` is the datastore proof-of-concept package. It contains the
mutation model used by the prototype app, plus small services for reading
`BookishRecord` values and applying local or remote mutations.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `BookishRecord`, `BookishRecordID`, and `BookishRecordValue` from the
  `BookishRecord` package for materialised records and property values.
- `MutationRecord`, `MutationOperation`, and `MutationID` for recording changes
  as an append-only mutation log.
- `RecordStore` and `MutationStore` protocols that keep persistence details out
  of the services.
- JSON-backed prototype stores in `JSONRecordStore` and `JSONMutationStore`.
- `DefaultRecordService` and `DefaultMutationService` for the first read/write
  service boundary.
- `DatastorePrototype`, a convenience bundle used by the app and integration
  tests.

The implementation intentionally uses JSON files so the projected record state
and mutation log can be inspected while the production SQLite and CloudKit
storage choices are still being explored.

Run the package tests from this directory with:

```sh
swift test
```
