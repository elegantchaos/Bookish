# 2026-09-25 Full Code Review

Reviewed the whole codebase at `main` commit `e1b56be` against the shared
`baseline:standards`, `swift:language`, `swift:swiftui`, `swift:concurrency`,
`swift:testing` and `swift:swiftdata` skills, with emphasis on SwiftUI
performance and Swift concurrency. The findings and a suggested order of work
are in [Code Review](../Documentation/Code%20Review.md).

The review was done by reading the code; no toolchain was available, so
nothing was built, tested or profiled.

Headline findings:

- Filter keystrokes and query-section views create `RecordQueryResult`s that
  are never released, so the cost of each mutation grows with use. This extends
  [Fine-Grained Record Observation](2026-09-25-fine-grained-record-observation.md).
- `DefaultMutationService` does read-modify-write across two actors without
  serialisation, so overlapping commands can lose updates.
- Seeding writes directly to the record projection rather than the mutation
  log, which conflicts with
  [Decision 0002](../Decisions/0002-mutation-log-and-record-projection.md).
- Import reading, reconciliation and freshness checks run on the main actor.

Open question for a decision: whether configuration seeds become mutations or a
separate, non-synced layer.
