# Project Specific Rules

- This repository is a Swift book-cataloguing app for macOS and iOS. Key features:
  - Flexible schema-less records with user-customisable fields
  - Intelligent barcode and bookshelf scanning
  - Metadata lookup and cleaning
  - macOS and iOS clients with automatic data synchronisation
  - clean and modern SwiftUI-based user interface
  - user defined book lists (reading/loans/library/to-read/etc)
- Use Swift Testing for tests; XCTest is tolerated only in external dependencies.
- Keep most storage behind the DataStore and BookishRecord abstractions.
- Use SwiftData only within the datastore; do not use Core Data.
- Keep a development journal in `Extras/Journal/`.
- Keep a decision log in `Extras/Decisions/`.
- Testing and validation may update Xcode and SwiftPM package lockfiles; keep those updates.
- Validate every Swift code change with `rt validate`.
- Create temporary files in `.build/tmp` at the repository root.

# Standard Rules

Read and follow @~/.local/share/agents/COMMON.md before starting work.

# Skills

- Follow the `baseline:standards` skill for all coding work.
- Use the `baseline:records` skill for journal and decision-log work.
- Use the `swift:language` skill for Swift language and package work.
- Use the `swift:swiftui` skill for SwiftUI view work.
- Use the `swift:testing` skill for Swift Testing work.
- Use the `swift:swiftdata` skill for SwiftData work.
- Use the `swift:validation` skill after Swift code changes.
- Use the `codex-git` skill for git operations.

To refresh this file, use the `baseline:refresh` skill.
