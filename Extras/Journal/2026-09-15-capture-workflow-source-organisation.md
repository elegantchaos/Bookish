# Capture Workflow Source Organisation

## Findings

- The recognition and capture changes had accumulated multiple top-level types in single source files, which did not meet the project's source-organisation rule.
- The image preview also decoded ImageIO data from a computed value evaluated by SwiftUI's `body`, putting avoidable work on the rendering path.

## Changes

- Split each capture view, recognition protocol, example-image loader, candidate-record extension, preview sizing policy, and preview-image loader into its own source file. Extensions remain in `Type+Functionality.swift` files.
- Moved the reusable test recognizer into `Tests/BookishAppTests/Fixtures/TestBookRecognizer.swift`.
- Completed declaration documentation in the affected capture and recognition code.
- Decode preview image data in a task, off the SwiftUI rendering path, through the cross-platform `CGImage` loader.

## Validation

- `swift test --package-path Dependencies/BookishApp --filter BookRecognitionTests` passed all three recognizer-preference tests.
- `rt validate --target BookishApp` passed the macOS target build (with an existing destination-selection warning).
- `rt validate` passed formatting, linting, and generic iOS and macOS application builds.
