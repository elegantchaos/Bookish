# BookishRecord

`BookishRecord` owns the canonical materialised record model used by the new
Bookish datastore prototype, importers, coding layer, and record views.

The package requires Swift 6.3 and macOS 26.

The package includes:

- `BookishRecordID`, the stable record identifier type.
- `BookishRecord`, a schema-less materialised record with `id`, `kind`, and
  properties.
- `BookishRecordValue`, the storage-neutral property value enum.
- `BookishEncodedValue`, an opaque JSON payload value for small Codable
  property payloads.
- `BookishBlobReference`, a lightweight reference to immutable out-of-line blob
  data.

Encoded payload properties can be read with an inferred result type:

```swift
let dimensions: Dimensions? = record.encoded("dimensions")
```

or with an explicit type when inference is not available:

```swift
let dimensions = record.encoded("dimensions", as: Dimensions.self)
```

Run the package tests from this directory with:

```sh
swift test
```
