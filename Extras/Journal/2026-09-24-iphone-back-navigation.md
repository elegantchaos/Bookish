# iPhone Back Navigation

## Finding

The iPhone recording shows the Books index after returning from *A Clash of Kings*, followed by an unsolicited push to the first book. `RecordIndexView` sends a nil selection through `SelectRecordCommand` during Back navigation. `BookishNavigationService.select(recordID: nil)` previously replaced that nil with the first record.

## Change

- Explicit record deselection now leaves `selectedRecordID` nil and clears linked-record navigation.
- Query refreshes preserve that cleared selection. Loading a new index still selects its first record by default, preserving the existing macOS behavior.
- Added a regression test for deselection and refresh. Isolated an existing index-seeding test from the user's persisted navigation preference.

## Verification

- The regression test failed before the fix and passed afterward.
- `swift test --package-path Dependencies/BookishApp` passed all 70 tests.
- `agt format` passed with three existing lint warnings in unrelated files. Formatting changes outside this task were reverted.
- `rt validate` passed formatting, linting, and generic iOS and macOS builds after the final test-isolation edit.
- The exact iPhone Back gesture has not yet been exercised on the updated build.
