# Import Toolbar Choices

The Import workflow now exposes Interchange, Delicious Library, and Kindle actions in its toolbar. The Delicious Library menu shows the bundled small and full samples in Advanced and Development modes, plus the file picker. The Kindle menu offers a synthetic test fixture and a database file picker on both macOS and iOS. The macOS Import menu also exposes the Kindle fixture and file choices.

The Kindle fixture moved from the importer test target into the existing samples target, so tests and the app use the same synthetic database. The Kindle file picker is view-owned on both platforms and passes its selected URL through a command to the importer service. The Import workflow's empty state points to the toolbar, and mentions the Import menu only on macOS.
