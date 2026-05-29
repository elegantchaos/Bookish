# DatastorePrototypeApp

`DatastorePrototype` is the thin Xcode app target for the datastore proof of
concept. It contains the `@main` application entry point and imports the
`DatastorePrototypeApp` library from `Dependencies/DatastorePrototypeApp`.

The app currently includes:

- `DatastorePrototypeApplication`, the SwiftUI `App` entry point.
- A dependency on `DatastorePrototypeApp`, which owns the prototype UI,
  harness model, seed data, and datastore actions.

Use the `DatastorePrototype` scheme in Xcode to run the prototype. The JSON
files are written under the user's Application Support directory in
`BookishDatastorePrototype`.
