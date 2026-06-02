# BookishRecord

`BookishRecord` owns the canonical materialised record model used by the new
Bookish datastore prototype, importers, coding layer, and record views.

The package requires Swift 6.3 and macOS 26.

The package includes:

- `BookishRecordID`, the stable record identifier type.
- `BookishRecord`, a schema-less materialised record with `id`, `kind`, and
  properties.
- `BookishRecordValue`, the storage-neutral property value enum.
- `BookishBlobReference`, a lightweight reference to immutable out-of-line blob
  data.

Run the package tests from this directory with:

```sh
swift test
```
