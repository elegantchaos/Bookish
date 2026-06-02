# DatastorePrototypeApp

`DatastorePrototypeApp` is the Swift package that contains the reusable code for
the datastore proof-of-concept app. The Xcode `DatastorePrototype` app target
keeps only the `@main` entry point and imports this package's library.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `DatastorePrototypeHarness`, the observable model that loads, seeds, refreshes,
  and mutates the prototype datastore using `BookishRecord` values.
- `PrototypeBrowserSelection`, the selection model for records and mutations.
- `DatastorePrototypeHarnessView`, the root SwiftUI split-view interface.
- Sidebar rows for records and mutations, record and mutation detail display,
  layout switching, mutation simulation, and the prototype status bar.

Run the package tests from this directory with:

```sh
swift test
```
