# Dependencies Review

Reviewed the Bookish-owned packages in `Dependencies/`, excluding git submodules: BookishApp, BookishCleanup, BookishCoding, BookishDatastore, BookishImporter, BookishRecord, and BookishRecordView.

## Completed cleanup

- Removed the unnecessary `@unchecked Sendable` conformance from the main-actor-isolated observable query result.
- Detached interchange and Delicious Library import producers so decoding and graph construction do not inherit a calling SwiftUI main actor.
- Removed commented-out settings declarations and the empty Advanced settings tab.
- Added documentation and access control to the new settings views.
- Split record presentation’s independent public layout-item, field, interaction-mode, and display-formatting types into focused source files.

## Follow-up design work

- `BookishHarness` combines datastore lifecycle, seed projection, import coordination, status reporting, query selection, and command-centre support. Its size and change rate make it the highest-priority candidate for decomposition around explicit services.
- `BookishCleanup` retains an old class hierarchy with nine detector subclasses in one source file and uses `try!` for every regular-expression definition. A replacement should use focused value types, compile patterns through an explicit error policy, and retain the current fixture coverage before removing the legacy hierarchy.
- Importers use `AsyncThrowingStream` with its default unbounded buffer. Record events cannot safely be dropped, so a bounded buffering policy would be incorrect. A future importer protocol should provide acknowledgement or demand-based batching to apply real back-pressure for very large libraries.
- `BookishAppTests` is a single large integration-test file. Split it by datastore startup, navigation, layout/query presentation, imports, and reset/recovery behavior to make fixtures and failures local.
- User-facing strings remain embedded across BookishApp, BookishImporter, and BookishRecordView. Introduce a string catalog with symbolic keys and generated accessors as one coordinated localization change rather than translating isolated literals.
