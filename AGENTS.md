Apply the rules below when working on this project.

# Project Specific Rules

- This repository is a Swift book cataloguing app for macOS and iOS, written using Swift 6 and SwiftUI.
- We use Swift Testing for tests (XCTest is only be tolerate in external dependencies).
- The project uses its own DataStore/BookishRecord abstraction for most data storage.
- SwiftData can be used for implementation within the datastore. CoreData should not be used anywhere.
- Keep a development journal in `Extras/Journal/`.
- Testing & validation may incidentally update xcode / swiftpm package lockfiles. This is acceptable and does not need to be reversed.
- Use `rt validate` to validate all Swift code changes, following the rules in the `swift-validation` skill.
- Before every Swift code change, review your proposed design and implementation to ensure that they are aligned with the rules laid out by `coding-standards` and  `swift` , and any other relevent skills. Revise the plan if not.
- After every Swift code change, review all affected code areas to ensure that they are still aligned with our standards. Consider the effect that your changes had on the coherence of the overall codebase, and not just the changes themselves. Call out any mis-alignment and propose corrections.
- When making temporary files, create them in `.build/tmp` in the project root, rather than using `/private/tmp`.

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
- If the solution to a task would be improved by refactoring existing code, do so, but ask permission first. Aim to complete and test the refactor of the existing code before implementing the new task.
- If unexpected workspace changes appear, pause and confirm direction before continuing.
- Keep `Extras/Journal/` as dated Markdown entries with an updated `Extras/Journal/index.md` when a work session produces useful context, research, prototype notes, findings, open questions, or implementation plans.
- Keep `Extras/Decisions/` as an explicit log of important decisions - one markdown file per decision. Check it if necessary before implementing new code, to ensure that it is aligned.

# Skills

- Follow the `coding-standards` skill for all coding work.
- Use the `swift` skill for Swift language and package work.
- Use the `swiftui` skill for SwiftUI view work.
- Use the `swift-testing-pro` skill for Swift Testing work.
- Use the `swiftdata-pro` skill when replacing CoreData with SwiftData.
- Use the `swift-validation` skill after code changes.
- Use the `codex-git` skill for git operations.

To refresh this file, use the `refresh` skill.
