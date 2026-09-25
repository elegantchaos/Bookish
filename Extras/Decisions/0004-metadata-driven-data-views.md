# 0004: Configure the browser and presentation with configuration records

- Status: Accepted
- Date: 2026-09-03

## Context

A schema-less catalogue needs flexible browsing and presentation without
hard-coded SwiftUI screens for every record kind, field, index, and layout.

## Decision

Layouts, indexes, and property-presentation metadata are ordinary records in the
same datastore as catalogue data. They determine how records are discovered,
ordered, labelled, and rendered; they do not constrain which properties or
values a record may contain.

Presentation resolves from generic metadata, then record-kind metadata, then
the active layout. Metadata members cascade individually, so a more-specific
override can change one concern without discarding the rest.

Viewer and editor identifiers are advisory. If metadata is absent, unknown, or
incompatible with a value, the UI uses a generated label and a safe generic
fallback.

## Alternatives considered

Hard-coded screens, browser tabs, and per-kind field schemas were rejected
because they couple ordinary catalogue evolution to SwiftUI changes. Strict
metadata validation was also rejected: metadata improves presentation but must
not make an otherwise valid custom or imported record unreadable.

## Consequences

- Standard layouts and indexes can be seeded while remaining inspectable and
  eventually user-editable.
- New record kinds and fields do not require a new fixed UI schema.
- Metadata cannot make otherwise valid stored data unreadable.
- Views receive resolved, stable presentation values instead of querying the
  record store while constructing `body`.
