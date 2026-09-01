# BookishApp

`BookishApp` is the Swift package that contains the reusable code for
the datastore proof-of-concept app. The Xcode `BookishDatastore` app target
keeps only the `@main` entry point and imports this package's library.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `BookishEngine`, the app-shell engine that owns and injects the
  datastore harness and navigation service.
- `BookishHarness`, the observable model that loads, seeds, refreshes,
  and mutates the datastore using `BookishRecord` values.
- `BookishNavigationService`, the record-browser routing service used
  by SwiftUI and navigation commands.
- `BookishHarnessView`, the root three-pane SwiftUI interface with
  record kind, record index, and record detail columns.
- Layout switching, linked-record navigation, mutation simulation, interchange
  import/export, Delicious Library import, and the datastore status bar.
- `BookishMutationDebugView`, a debug-only mutation browser designed
  for a separate window so the main record UI does not read mutation state.

Run the package tests from this directory with:

```sh
swift test
```
