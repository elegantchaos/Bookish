# Shared import review — 2026-09-24

## Work

- Added a storage-neutral reconciliation plan to `BookishImporter`. It compares proposed records with a catalogue snapshot, marks exact repeats for skipping, and exposes possible matches for explicit review. Resolution remaps links when a proposed author, publisher, or other related record reuses an existing catalogue record.
- Changed `BookishImportingService` to collect every importer stream into a proposal. Kindle, Delicious Library, and Bookish interchange now use the same prepare/apply flow. The service checks the catalogue snapshot again before applying reviewed records.
- Added a review sheet in BookishApp. The user can keep or replace a conflicting record with the same ID, or add a separate record or reuse a suggested record with a different ID. Cancelling leaves storage untouched.
- Removed Kindle-specific existing-ID filtering. The Kindle importer now preserves a JSON source snapshot in `originalData`, writes source and imported IDs on related records, handles multiple authors, and converts `Surname, Other Names` author names for display. The synthetic SQLite fixture exercises those cases.
- Added planner and app tests for link remapping, repeat imports, explicit choices, delayed writes, and stale-plan rejection. The copied private Kindle database remains outside version control; its optional test still finds 280 book rows.
- Suppressed unused related-record proposals when every referring external book is skipped. Repeat runs therefore do not ask the user to review the same manual author again.

## Limits and follow-up

- Cross-source book candidates currently use ASIN or ISBN, and related-record candidates use normalized exact names. Ambiguous matches require review. This is an initial policy, not a general duplicate detector for scanning or cleanup.
- The full catalogue snapshot is checked before applying a plan. Storage currently persists each surviving record as a separate mutation, so an error partway through that write could leave a partial import. A transactional batch operation would close that gap.
- Kindle's `Purchase` and `Sharing` values remain in `originalData`; ownership classification still needs evidence about their meaning. Interactive testing of the macOS permission picker remains open.
- The previous Kindle importer journal entry describes its original source-scoped skip mechanism. This entry supersedes that implementation detail.
