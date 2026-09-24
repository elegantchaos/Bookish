# Import workflow review — 2026-09-24

## Work

- Routed Import commands and direct import operations into the existing Import workflow. The workflow shows reading progress, proposal review, failures, and a summary with added records after apply. The old review sheet was removed.
- Possible matches now start with the existing catalogue record selected. A conflicting same-ID record starts with "Use Existing"; a different-ID match starts with a deterministic existing candidate. The user can still choose to add or replace the proposed record.
- Replaced each row's radio-style buttons with a compact choice menu. On macOS, the review list supports Command/Shift row selection and a bulk menu to use existing or imported records for the selected rows.
- Preserved pending proposals until applied or cancelled, so another Import command does not silently discard a review in progress. Added focused tests for navigation, default and bulk choices, and completed results.

## Follow-up

- Multiple possible existing candidates default to the one with the lexicographically first record ID. This gives a stable choice, but the reviewer should inspect those ambiguous rows before applying an import.
- Interactive visual verification on macOS and iOS is still useful, especially for the row menu and macOS multi-selection behaviour.
