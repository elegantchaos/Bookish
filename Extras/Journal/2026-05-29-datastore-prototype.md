# Datastore Prototype

Started the datastore proof-of-concept described in `Extras/Documentation/Datastore Implementation.md`.

Initial implementation scope:
- `Dependencies/BookishDatastore` contains protocol-first record and mutation services, JSON-backed local stores, mutation application, and tests.
- `Dependencies/BookishRecordView` contains a prototype SwiftUI `PrototypeRecordView` driven by a data record and a layout record.
- `Sources/DatastorePrototypeApp` contains a small macOS SwiftUI harness that seeds records, shows them through the record view, and creates local or simulated remote mutations.

The prototype intentionally uses file-based JSON persistence so the projection and mutation log are easy to inspect while the SQLite and CloudKit decisions remain open.

Follow-up documentation:
- Added README files for `Dependencies/BookishDatastore`, `Dependencies/BookishRecordView`, and `Sources/DatastorePrototypeApp` summarizing each prototype component.

Prototype browsing update:
- Added a shared record presentation adapter and `PrototypeRecordCell` so record rows and detail views both use layout records without duplicating formatting logic.
- Updated `DatastorePrototypeApp` to browse all records from the record service, select records in a split view, and switch the active layout from the toolbar.
- Added mutation browsing with shared mutation presentation helpers, a mutation row view, a mutation detail view, and a Mutations section in the prototype sidebar.
- Moved the prototype harness and SwiftUI UI into a new `Dependencies/DatastorePrototypeApp` package, leaving the renamed `DatastorePrototype` Xcode app target as a thin entry point.
