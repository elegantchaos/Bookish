# BookishCapture Cleanup

## Changes

- Standardised recognizer terminology and registry API names.
- Made registry lookup failures explicit and documented the package surface.
- Simplified provider comments to describe their current contracts.
- Restored an injectable HTTP transport for deterministic OpenAI recognizer tests.
- Moved package-owned fake and OpenAI recognizer tests out of `BookishApp`.

## Validation

- `rt validate --target BookishCapture` built the package and passed `BookishCaptureTests`.
- Full-project and `BookishApp` validation did not return before the environment's execution cutoff.
