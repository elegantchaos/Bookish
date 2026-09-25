# Project Specific Rules

- Before changing app behavior or user-facing workflows, read `README.md`.
- Use Swift Testing when writing tests.
- Keep most storage behind the DataStore and BookishRecord abstractions.
- Use SwiftData only within the datastore implementation; do not use Core Data.
- Keep a development journal in `Extras/Journal/`.
- Keep a decision log in `Extras/Decisions/`.
- Ask before adding migrations, shims or indirection layers for compatibility; I am the only developer and currently the only user.
- Use `feature/` branches for new work. Avoid interleaving unrelated changes in the same feature branch.

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
