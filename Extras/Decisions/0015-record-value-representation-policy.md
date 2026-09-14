# 0015: Choose record-value representations by semantic scope

- Status: Accepted
- Date: 2026-05-28

## Context

Bookish needs flexible record properties while preserving discoverability,
interchange compatibility, fine-grained mutation behavior, and support for
future data-driven interfaces.

## Decision

Use primitive record values for values directly representable as JSON primitives,
such as strings, integers, doubles, booleans, and lists.

Use dedicated plumbing representations for datastore concerns, including record
links, blob references, tombstones, deletion markers, and conflicts.

Use tagged encoded values for small, self-contained domain values with
application-specific semantics, such as dates and URLs. An encoded value may
carry a stable kind hint when decoding needs one.

Use a linked record when a value has its own identity or lifecycle, is large,
contains inspectable fields, or represents a dictionary or multi-level
structure. Such values remain discoverable and can participate in ordinary
record relationships and presentation.

## Alternatives considered

Encoding every compound value as opaque data was rejected because individual
fields become undiscoverable, edits replace the entire value, and conflicts grow
coarser. Creating a dedicated low-level value case for every domain type was
rejected because it would make the storage model rigid. Storing large binary data
inline was rejected in favour of out-of-line blob references.

## Consequences

- The low-level value model stays small while supporting rich domain values.
- Small encoded values remain convenient but do not replace linked records where
  fields need independent lifecycle, presentation, or mutation behavior.
- Import, interchange, and UI code can distinguish datastore plumbing from
  ordinary application data.
