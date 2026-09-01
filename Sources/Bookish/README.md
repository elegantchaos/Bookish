# BookishApp

`Bookish` is the thin Xcode app target for the datastore proof of
concept. It contains the `@main` application entry point and imports the
`BookishApp` library from `Dependencies/BookishApp`.

The app currently includes:

- `BookishApplication`, the SwiftUI `App` entry point.
- A dependency on `BookishApp`, which owns the Bookish UI,
  harness model, seed data, and datastore actions.

Use the `Bookish` scheme in Xcode to run the app. The JSON
files are written under the user's Application Support directory in
`BookishDatastore`.
