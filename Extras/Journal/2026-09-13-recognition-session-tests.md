# Recognition Session Tests

## Design

- `OpenAIResponsesBookRecognizer` accepts a concrete `URLSession`, defaulting to `.shared`. A comment explains that session injection allows offline tests using Foundation's `URLProtocol` interception.
- No transport protocol or production networking wrapper is required.
- The test-only `RecordingRecognitionSession` configures an ephemeral session to return a canned response and record the outgoing request. A locked registry routes callbacks to separate fixtures so parallel tests do not share response or request state. Tests close their sessions and remove registrations with `defer`.
- Existing image payload, authorization, decoding, and missing-credential checks are preserved, with an explicit POST-method assertion. HTTP body streams are captured for request assertions.

## Validation

- Red: targeted validation failed because the updated tests passed a `session` argument before the recognizer supported it.
- Green: `rt validate --target BookishCapture --package-dirs Dependencies/BookishCapture` built the target and passed all five tests without warnings.
- Comprehensive `rt validate` passed formatting, lint, and the Bookish iOS and macOS builds without warnings. Live recognition and network integration were not exercised.
