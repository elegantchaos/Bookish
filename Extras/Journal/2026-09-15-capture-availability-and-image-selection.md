# Capture Availability and Image Selection

## Changes

- `BookRecognizer` now exposes `isSupported`. The direct-image On Device and Cloud Compute recognizers report unavailable before macOS or iOS 27, so their capture-menu commands are disabled on macOS 26.
- The recognizer registry's pending additions for OCR and OpenAI were preserved.
- Image selection no longer begins recognition. The Capture view offers a Choose Image menu with Photos, File, and bundled-example sources, followed by a command-backed Capture Books action.
- Image files are read through the security-scoped URL returned by the file importer, and failures are reported through the app status service.
- On macOS, the controls and preview remain side by side in the upper capture pane. A vertical split separates that workspace from the independently scrolling candidate list below; the upper pane starts with a 128-point ideal height, half the preview's former fixed 256-point height. The recognizer menu label is "Choose Method".

## Validation

- `swift test --package-path Dependencies/BookishCapture` passed all five tests, including the macOS-26 availability regression test.
- `swift build --package-path Dependencies/BookishApp` passed.
- `swift test --package-path Dependencies/BookishApp` could not compile its existing stale recognition tests, which reference removed `BookRecognitionViewModel` and related types. This predates the capture change; the app source itself builds successfully.
