# Data Cleanup

Bookish data cleanup finds and repairs catalogue metadata that is inconsistent,
duplicated, or embedded in the wrong field. It is a review workflow, not an
unattended rewrite. The user sees the evidence, proposed change, and affected
records before any durable mutation is made.

## Current Capability

`Dependencies/BookishCleanup` is used only by the Delicious Library importer.
It has two text-only cleaners:

- `SeriesCleaner` uses eight ordered regular-expression detectors to extract a
  series name and integer position from a book title or subtitle. It can also
  remove repeated series text and handle some `Part n` cases.
- `PublisherCleaner` removes a publisher name, optionally with a `Books`
  suffix, when it has been appended to a title in parentheses or duplicated as
  the subtitle.

The importer applies the publisher cleaner first and the series cleaner second,
then creates a normalised graph. Related records receive deterministic IDs made
from their imported name. This prevents exact-name duplicates in one import but
does not find near duplicates such as punctuation, whitespace, spelling, or
article differences. Existing catalogue records are never scanned, and neither
cleaner understands record links or persists mutations itself.

The series fixtures are valuable regression examples, but the implementation is
legacy-shaped: mutable classes, hidden detector ordering, `try!` regular
expressions, limited diagnostics, and a package README without an operational
contract. It should be replaced rather than extended in place.

## Scope

The initial cleanup feature should inspect `book`, `person`, `series`, and
`organisation` records. Its checks should be small, deterministic, and
independently selectable:

- normalise Unicode, whitespace, quotation marks, dash punctuation, and
  punctuation spacing without changing the meaning of a value;
- flag title/subtitle candidates, including delimiters embedded in `name`, but
  never assume that a colon always introduces a subtitle;
- extract series and number candidates from book `name` and `subtitle`, using
  the current series fixtures as the starting corpus;
- identify exact and near-duplicate people, series, and organisations using a
  normalised comparison key, followed by conservative similarity thresholds;
- flag likely typing, spelling, casing, or formatting anomalies for review.

Identifiers, source data, user notes, reading status, and arbitrary properties
are out of scope for automatic change. They may provide corroborating evidence,
but cleanup must not silently alter them.

## Domain Model

Create a storage-neutral `BookishCleanup` domain API that operates on
`BookishRecord` snapshots but does not import `BookishDatastore` or SwiftUI.
Keep the package focused on analysis and plans:

```swift
struct CleanupIssue: Identifiable, Sendable {
  let id: CleanupIssueID
  let rule: CleanupRule
  let severity: CleanupSeverity
  let evidence: CleanupEvidence
  let proposal: CleanupProposal
}
```

`CleanupProposal` should model only explicit choices: set or delete a property,
split a value into two properties, or merge a named set of records into a chosen
canonical record. Each proposal includes its preconditions (record IDs and
expected values), an explanation, confidence, and whether user confirmation is
required. A plan is immutable once displayed; applying it must re-read its
targets and reject stale preconditions rather than overwrite later edits.

Text normalisation is a comparison aid, not a canonical display transformation.
It should use locale-independent Unicode normalization and a documented set of
punctuation rules. A user-selected canonical name remains the source of truth.

## Merging Records

Record merging is materially different from editing a name. To merge duplicates,
the feature must:

1. Choose a canonical record without changing its stable ID.
2. Find every record that links to a duplicate, including links nested in lists.
3. Replace each duplicate link with the canonical link while preserving list
   order and removing only newly adjacent duplicate links where the property
   contract requires uniqueness.
4. Resolve compatible scalar properties deliberately, preserve conflicts for
   review, and retain source/original-data provenance.
5. Delete or tombstone the absorbed records only after all inbound links are
   rewritten, using the datastore's final deletion semantics.

The current `MutationOperation` supports property changes and record deletion,
but lacks an atomic graph-rewrite/merge operation and tombstone application.
Do not fake a merge with arbitrary `upsertRecord` calls. First add a durable,
idempotent semantic operation such as `mergeRecords(canonicalID:duplicateIDs:)`,
with the full rewrite policy and undo/audit data. The mutation service then owns
the projection update and query refresh.

## Application Integration

Add a `BookishCleanupService` above the datastore. It reads record snapshots,
runs a selected set of rules off the main actor, vends an observable review
model, and applies accepted plans through the mutation service. It should depend
on narrow read and write protocols so that rule, service, command, and view
tests can use fixtures.

Expose a dedicated `Data Cleanup` area at the top of the browser sidebar,
replacing the current non-interactive `Coming Soon` label in
`BrowserIndexListView`. It should push its own SwiftUI view rather than pretend
to be a record index. The view has three stages:

- **Scan**: choose record kinds and rules, then show progress and an empty
  state when no issues are found.
- **Review**: group issues by rule; show original and proposed values, linked
  records, confidence, and evidence; allow accept, reject, edit, and a single
  selected canonical record for a merge.
- **Apply**: confirm the exact number and type of mutations, apply only
  accepted fresh proposals, and show successes, conflicts, and stale proposals.

The top-level item should use a labelled `Button` or navigation value with an
accessible name such as `Data Cleanup`, not an icon-only control. Its view
model owns scanning/applying state; SwiftUI rows receive stable issue values and
contain no datastore writes in `body`.

Add a command-backed `Open Data Cleanup` action so the same destination can be
reached from the menu and sidebar. The app host should only compose this route,
the service, and its command provider.

## Apple Foundation Models

The local FoundationModels SDK exposes `SystemLanguageModel` and
`LanguageModelSession` on iOS, macOS, and visionOS 26 and later. It supports
availability inspection, typed guided output through `@Generable`, and async or
streamed responses. The system model can be unavailable because the device is
ineligible, Apple Intelligence is disabled, or its model is not ready. Bookish
already targets macOS and iOS 26, so this can be an optional on-device reviewer,
not a requirement for cleanup.

Use the model after deterministic candidate generation, never as the initial
catalogue-wide matcher and never as a direct mutation authority. Give it a small
bounded candidate group and require a typed result containing: `keepSeparate`,
`possibleDuplicate`, `proposedName`, `proposedTitle`, `proposedSubtitle`,
`rationale`, and confidence. Validate every generated value against the same
record/property rules used by manual proposals; present it as a confirmation-only
suggestion. No model output may invent record IDs, external facts, or links.

The best first AI experiments are ambiguous title/subtitle splits and near-name
duplicate candidate ranking. Punctuation normalization, exact duplicates, and
known series patterns remain deterministic rules. Provide a clear unavailable
state and retain the complete non-AI workflow. Record the model's availability,
rule/version, input record IDs, and generated proposal in the local audit trail,
but do not persist conversational text or send catalogue data to a remote model.

## Delivery Plan

1. Replace the legacy cleaners with pure, `Sendable` analysis rules and migrate
   all current series/publisher fixtures unchanged. Add fixtures for punctuation,
   title/subtitle ambiguity, and duplicate candidate false positives.
2. Define `CleanupIssue` and `CleanupProposal`, normalised comparison keys, and
   a batch scanner. Test determinism, no-op behavior, confidence thresholds, and
   diagnostics with `Swift Testing`.
3. Add narrow cleanup read/write protocols and `BookishCleanupService`; use
   durable property mutations for accepted simple edits and reject stale plans.
4. Design and test a dedicated datastore record-merge operation before exposing
   merge acceptance in the UI. Include repeated application, inbound-link
   rewriting, conflicts, and projection rebuild tests.
5. Add the `Data Cleanup` sidebar route, command, review model, previews, and
   accessibility coverage. Replace `Coming Soon` only when the scan screen is
   functional.
6. Prototype a Foundation Models adapter behind a protocol with availability and
   generated-output fixtures. Evaluate it on a curated, consented sample against
   the deterministic baseline before enabling it in the product.

## Open Decisions

- What canonical-name policy should apply to people: display order, initials,
  diacritics, honorifics, and suffixes?
- Should merge preserve absorbed records as tombstones, redirects, or both?
- Which list properties promise uniqueness, if any?
- What audit/undo retention is needed before destructive merge support?
- Which locales and language scripts must the first punctuation and spelling
  rules support?
- What confidence and review evidence are sufficient for an AI suggestion?
