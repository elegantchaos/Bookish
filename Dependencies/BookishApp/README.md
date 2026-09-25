# BookishApp

`BookishApp` is the Swift package that contains the reusable code for
the datastore proof-of-concept app. The Xcode `BookishDatastore` app target
keeps only the `@main` entry point and imports this package's library.

The package requires Swift 6.3 and macOS 26.

The package currently includes:

- `BookishEngine`, the composition root and command centre. It owns the
  services and vends each service's command `API` to commands.
- `BookishCommander`, the command façade injected into SwiftUI.
- Application services in `Services/`, each with the nested
  `State`/`API`/`Access` shape described in
  `Extras/Documentation/Command and Environment Design.md`: storage, navigation,
  presentation, browser refresh, status, importing, exporting, record creation,
  record actions, recognition, lookup, and settings presentation.
- Commands in `Commands/`, each generic over the smallest service `Access` protocol.
- `BookishRootView`, the root SwiftUI interface with the sidebar, record index,
  record detail, and workflow views.
- `BookishMutationDebugView`, a debug-only mutation browser designed
  for a separate window so the main record UI does not read mutation state.

Run the package tests from this directory with:

```sh
swift test
```
