# DatastorePrototypeApp

`DatastorePrototypeApp` is a small macOS SwiftUI harness for the datastore proof
of concept. It is an Xcode app target that wires together `BookishDatastore` and
`BookishRecordView`.

The app currently includes:

- A `DatastorePrototypeHarness` model that creates the JSON-backed datastore in
  Application Support.
- Seed data for prototype book, author, and layout records.
- A record index fetched from the record service.
- A mutation index fetched from the mutation store.
- Selection-driven record and mutation detail display.
- A layout picker that changes how the selected record and index rows are
  rendered.
- Toolbar actions that create local status mutations.
- A simulated remote mutation action that appends a remote change through the
  mutation service.
- A compact status bar showing the latest action, record count, and mutation
  count.

Use the `DatastorePrototypeApp` scheme in Xcode to run the prototype. The JSON
files are written under the user's Application Support directory in
`BookishDatastorePrototype`.
