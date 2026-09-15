# Recognition Method Persistence

## Changes

- The capture workflow's **Choose Method** menu already renders the selected recognizer's label. `BookishRecognitionService` now restores that selection from the existing `bookRecognitionProvider` app setting when the app starts and saves each supported selection made through `SelectRecognizerCommand`.
- `BookRecognitionMethodPreference` makes the `UserDefaults` dependency explicit and testable instead of using `@AppStorage` inside the observable recognition service. An unregistered stored identifier safely falls back to a registered recognizer.
- The capture top pane now claims the available width, allowing its existing spacer to place the selected image preview against the trailing edge rather than only just beyond centre.
- Recognition command tests now use the current command and service interfaces, so the focused persistence test can compile and run with the capture workflow.

## Validation

- `swift test --package-path Dependencies/BookishApp --filter 'BookRecognitionTests|CommandProviderTests.recognitionCommandsSelectAMethodAndCaptureTheImage'` passed both focused tests.
