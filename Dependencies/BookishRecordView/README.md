# BookishRecordView

`BookishRecordView` is the SwiftUI proof-of-concept package for rendering
Bookish records. It displays a `BookishRecord` data record using a separate
layout record, and depends on `BookishDatastore` only for mutation presentation
types.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `BookishRecordPresentation`, a shared layout adapter used by both row and
  detail views.
- `BookishMutationPresentation`, a shared adapter for displaying mutation log
  entries.
- `BookishRecordView`, a simple form-based record renderer.
- `BookishRecordCell`, a compact row renderer for record indexes.
- `BookishMutationView` and `BookishMutationCell` for browsing mutation
  details and rows.
- Layout-driven field selection through a layout record's `fields` property.
- Custom record-field value rendering through `BookishRecordView`, allowing
  callers to supply active controls for values such as record links without
  coupling this package to app-specific navigation services.
- Basic display formatting for `BookishRecordValue`.
- SwiftUI previews with sample book records and layout records.
- Focused tests for layout interpretation, mutation formatting, and view
  construction.

This package is deliberately small. Its role is to prove the boundary between
generic datastore records and a SwiftUI record presentation layer before the
real Bookish editing experience is built.

Run the package tests from this directory with:

```sh
swift test
```
