# Datastore Prototype

Started the datastore proof-of-concept described in `Extras/Documentation/Datastore Implementation.md`.

Initial implementation scope:
- `Dependencies/BookishDatastore` contains protocol-first record and mutation services, JSON-backed local stores, mutation application, and tests.
- `Dependencies/BookishRecordView` contains a prototype SwiftUI `PrototypeRecordView` driven by a data record and a layout record.
- `Sources/DatastorePrototypeApp` contains a small macOS SwiftUI harness that seeds records, shows them through the record view, and creates local or simulated remote mutations.

The prototype intentionally uses file-based JSON persistence so the projection and mutation log are easy to inspect while the SQLite and CloudKit decisions remain open.
