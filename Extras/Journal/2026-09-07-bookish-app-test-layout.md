# BookishApp Test Layout

Split the BookishApp integration tests by behaviour while retaining the existing `BookishAppTests` Swift Testing suite and stable test names.

- `BookishAppTests.swift` now concentrates on harness startup, seeded configuration, layouts, and settings behaviour.
- `BookishAppNavigationTests.swift` covers selection, navigation commands, selected layouts, and record-link presentation.
- `BookishAppImportTests.swift` covers interchange and Delicious Library import, export, projection rebuild, and datastore reset.

Shared fixture helpers remain on the suite with internal test-target visibility so extension files can use the same isolated temporary datastore setup.
