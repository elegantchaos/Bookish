# Project Specific Rules

- This repository is a Swift book cataloguing app.
- It is written using Swift 6 and SwiftUI.
- All new unit and integration tests must use Swift Testing. Never write new XCTest tests under any circumstances; existing XCTest tests in external dependencies may remain unchanged.
- The project uses its own DataStore/BookishRecord abstraction for most data storage.
- SwiftData may be used only as possible implementation for the mutation layer of the datastore.
- CoreData should not be used anywhere.
- Keep a development journal in `Extras/Journal/`.
- Testing & validation may incidentally update xcode / swiftpm package lockfiles. This is acceptable and does not need to be reversed.
- Use `rt validate` as the canonical Swift validation command. `rt validate --target <name>` builds the target and runs its matching SwiftPM test target when present; if `rt` cannot cover the required check, tell the user and offer to run direct `swift test` or `swift format` commands

# Standard Rules

- Always write modern, idiomatic code and prefer root-cause fixes over layered workarounds.
- Keep interfaces explicit and intentionally small; avoid hidden coupling and surprising side effects.
- Apply DRY and Single Source of Truth. Use KISS, YAGNI, Make Illegal States Unrepresentable, Dependency Injection, Composition Over Inheritance, Command-Query Separation, Law of Demeter, Structured Concurrency, Design by Contract, and Idempotency where they fit the problem.
- Inspect relevant code and documentation before editing, then keep the change scope aligned with the request.
- Use red/green TDD for non-UI code: write or update a failing test that captures the intended behavior, implement the change, then verify the test passes.
- Create UI previews for UI code whenever the tooling supports it.
- Add or update tests for behavior changes and use `rt` to run the narrowest validation that proves the change before broadening to relevant project checks.
- Report validation performed, skipped validation with reasons, residual risks, and any follow-up work that remains.
- Prefer trusted primary sources for technical decisions, especially official platform, language, package, API, and dependency documentation.
- Use portable path references in documentation: repository-relative paths for files in this repository and home-relative paths for shared resources outside it.
- When a required Mint-installed command is unavailable on `PATH`, use `~/.mint/bin/<command>` as a fallback before treating the tool as missing.
- Never expose or commit credentials or secrets.
- Never perform irreversible destructive actions without explicit approval.
- Reversible source-control changes, including deletion of tracked files, are allowed when they are part of the requested work.
- Avoid unrelated refactors during focused tasks; suggest them as follow-up work when they are needed.
- If unexpected workspace changes appear, pause and confirm direction before continuing.
- Keep `Extras/Journal/` as dated Markdown entries with an updated `Extras/Journal/index.md` when a work session produces useful context, research, prototype notes, findings, open questions, or implementation plans.

# Skills

- Follow the `coding-standards` skill for all coding work.
- Use the `swift` skill for Swift language and package work.
- Use the `swiftui` skill for SwiftUI view work.
- Use the `swift-testing-pro` skill for Swift Testing work.
- Use the `swiftdata-pro` skill when replacing CoreData with SwiftData.
- Use the `swift-validation` skill after code changes.
- Use the `codex-git` skill for git operations.

To refresh this file, use the `refresh` skill.
