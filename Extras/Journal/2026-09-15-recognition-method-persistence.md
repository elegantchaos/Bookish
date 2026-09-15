# Recognition Method Persistence

## Changes

- The capture workflow presents its selected recognizer through a menu-style picker beside a fixed **Method** label. The picker supplies the native selected-item checkmark, while selection still runs through `SelectRecognizerCommand`.
- `BookishRecognitionService` restores the selection from the existing `bookRecognitionProvider` app setting when the app starts and saves each supported selection made through `SelectRecognizerCommand`.
- `BookishRecognitionService` directly reads and writes the typed `bookRecognitionProvider` key through the `Settings` package's `UserDefaults` API. Its injected settings store remains testable, and an unregistered or unavailable stored identifier safely falls back to an available recognizer.
- The method picker shows all registered recognizers, disabling unavailable methods so their existence remains discoverable. A persisted but unavailable selection falls back to the first available recognizer.
- The capture top pane now claims the available width, allowing its existing spacer to place the selected image preview against the trailing edge rather than only just beyond centre.
- Recognition command tests now use the current command and service interfaces, so the focused persistence test can compile and run with the capture workflow.

## Validation

- `swift test --package-path Dependencies/BookishApp --filter BookRecognitionTests` passed the saved-setting plus unregistered- and unavailable-setting fallback tests.
- `rt validate --target BookishApp` passed the macOS `BookishApp` scheme build with Xcode warnings.
- `rt validate` passed formatting, linting, and `Bookish` builds for generic iOS and macOS destinations.
