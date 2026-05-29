# BookishRecordView

`BookishRecordView` is the SwiftUI proof-of-concept package for rendering
datastore records. It depends on `BookishDatastore` and displays a data record
using a separate layout record.

The package currently includes:

- `PrototypeRecordPresentation`, a shared layout adapter used by both row and
  detail views.
- `PrototypeRecordView`, a simple form-based record renderer.
- `PrototypeRecordCell`, a compact row renderer for record indexes.
- Layout-driven field selection through a layout record's `fields` property.
- Basic display formatting for the prototype datastore value types.
- SwiftUI previews with sample book records and layout records.
- Focused tests for layout interpretation and view construction.

This package is deliberately small. Its role is to prove the boundary between
generic datastore records and a SwiftUI record presentation layer before the
real Bookish editing experience is built.

Run the package tests from this directory with:

```sh
swift test
```
