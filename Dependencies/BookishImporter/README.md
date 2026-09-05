# BookishImporter

`BookishImporter` imports external library data into `BookishRecord` graphs.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `BookishImportResult`, the provider-neutral import result.
- `DeliciousLibraryImporter`, which imports Delicious Library XML property-list
  exports.
- Normalised graph output containing book, person, organisation, series,
  relationship, and root list records.
- Tests that import the Delicious sample data and round-trip the result through
  `BookishCoding`.

This package is intentionally separate from the legacy `BookishImporter` so the
main app can continue to build against the existing import path during the
migration.

Run the package tests from this directory with:

```sh
swift test
```
