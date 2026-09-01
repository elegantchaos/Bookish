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

## Per-Record JSON Projection

- Replaced the prototype record projection's monolithic `records.json` file with a `records/` directory containing one safely encoded JSON filename per record.
- Upserting an unchanged record now performs no file write; modifying one record leaves the other record files untouched.
- Added a one-time, non-destructive migration from the legacy `records.json` projection. The legacy file is retained after successful migration.
- The mutation log is still a single `mutations.json` file and remains the next material persistence bottleneck for large imports.

## Per-Mutation JSON Log

- Replaced the prototype mutation log with immutable JSON files in `mutations/records/` and local applied-checkpoint markers in `mutations/applied/`.
- Preserved the append, replay, and applied-checkpoint contract of `MutationStore`, keeping the persistence boundary suitable for a future cloud-backed mutation implementation while records stay local-only.
- Added a non-destructive migration from the legacy `mutations.json` log; the legacy source file remains after migration.

## Bundled Delicious Import Commands

- Replaced the single Delicious Library import menu command with an `Import Delicious Library` submenu containing `Small Sample`, `Full Sample`, and `Other…`.
- Moved the Delicious XML sample resources into `BookishImporterNu`, so the modern importer is self-contained and the prototype no longer needs the legacy importer package.
- The two sample commands import their bundled files directly; `Other…` retains the view-owned file picker for a user-selected XML export.

## Importer and Sample Product Boundary

- Kept the `BookishImporterNu` package name while renaming its importing target, module, and primary library product to `BookishImporter`.
- Moved the XML resources and their lookup API into a separate `BookishImporterSamples` target and library product.
- `BookishApp` links both products for its sample commands; shipping applications can link only the `BookishImporter` product when they do not need bundled fixtures.

## Bookish App Rename

- Renamed the active datastore app package, product, target, tests, Xcode target, and app bundle to `BookishApp` and `Bookish`.
- Renamed the app-layer APIs to `BookishApp…`, the datastore service bundle to `BookishDatastore`, and reusable record and mutation views to `Bookish…` names.
- Moved the older, unused `Dependencies/BookishApp` package intact to `Extras/Legacy/BookishApp` before assigning its canonical path to the active app package.
