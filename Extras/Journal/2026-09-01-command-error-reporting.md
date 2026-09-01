# Command Error Reporting

## Context

Fire-and-forget commands were only logged when they threw, leaving the datastore prototype's visible status area unchanged. Import commands also hosted their file importer on menu and toolbar controls rather than the main prototype view.

## Implementation Notes

- Added `CommandCentre.recordCommandFailure(_:error:)` as an overridable reporting hook.
- Kept log output as the default behaviour for command centres without a user-facing error surface.
- Routed `DatastorePrototypeHarness` command failures to its existing status message, which is displayed in the bottom status bar.
- Changed import menu and toolbar commands to request the main view's existing file importer, and route picker errors through the same status message.
- Added a debug-only `Throw Test Error` menu command to exercise the command error path in a running Prototype app.

## Validation

- Focused `Commands` Swift Testing regression test for a thrown fire-and-forget command.
- `DatastorePrototypeApp` XCTest coverage for command failure reporting, picker presentation, the visible debug error command, and invalid Delicious data reaching the status message.

## Follow-Up

- Import persistence still writes the JSON mutation and projection files for every upsert. The new progress UI makes that work visible, but profiling and a batch persistence API are needed before treating large imports as performant.

## Streaming Import Architecture

- Added the generic `BookishImporter` protocol to `BookishImporterNu`; importers emit start, progress, record-batch, diagnostic, and completion events.
- Refactored Delicious Library importing to emit normalised record batches while retaining its shared-record de-duplication graph. The final root list remains an end-of-import record.
- Added `BookishInterchangeImporter`, which adapts the existing synchronous `BookishInterchangeCodec` into the same stream. The codec remains the single decoder for interchange JSON.
- Added a deliberately unavailable `KindleLibraryImporter` stub and source type, reserving the shared API without guessing Kindle’s eventual extraction mechanism.
- Refactored the prototype harness to consume any importer event stream, apply emitted records as upserts, and drive an indeterminate or determinate `ProgressView` in the status bar.
