# Swift Testing Migration

All Bookish-owned unit-test targets now import `Testing`, use `@Test` suites, and express assertions with `#expect`, `#require`, and `#expect(throws:)`.

The migration removes the direct `XCTestExtensions` dependency from `BookishCore`; external dependency tests, including Logger, remain unchanged.

Focused package tests passed for BookishApp, BookishCleanupNu, BookishCoding, BookishDatastore, BookishImporterNu, BookishRecord, and BookishRecordView. `BookishCore` could not build because its existing use of `JSONSerialization.ReadingOptions.json5Allowed` needs a macOS 12 availability annotation or deployment-target update.

The repository guidance now requires Swift Testing for every new unit and integration test and prohibits adding XCTest tests anywhere. Existing XCTest tests in external dependencies remain unchanged.
