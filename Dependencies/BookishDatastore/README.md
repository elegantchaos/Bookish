# BookishDatastore

`BookishDatastore` is the datastore proof-of-concept package. It contains the
mutation model used by the datastore app, plus small services for reading
`BookishRecord` values and applying local or remote mutations.

The package requires Swift 6.3 and macOS 26.

The package depends on `BookishRecord` for the shared materialised record model:

- `BookishRecord` for materialised records.
- `BookishRecordID` for record identity.
- `BookishRecordValue` for record property values.

The package defines datastore-specific infrastructure:

- `MutationRecord`, `MutationOperation`, and `MutationID` for recording changes
  as an append-only mutation log.
- `RecordStore` and `MutationStore` protocols that keep persistence details out
  of the services.
- JSON-backed datastore stores in `JSONRecordStore` and `JSONMutationStore`.
- `DefaultRecordService` and `DefaultMutationService` for the first read/write
  service boundary.
- `BookishDatastore`, a convenience bundle used by the app and integration
  tests.

The implementation intentionally uses JSON files so the projected record state
and mutation log can be inspected while the production SQLite and CloudKit
storage choices are still being explored.

Run the package tests from this directory with:

```sh
swift test
```
