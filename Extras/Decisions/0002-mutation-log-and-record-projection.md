# 0002: Use a mutation log and materialised record projection

- Status: Accepted
- Date: 2026-05-28

## Context

Bookish needs local-first catalogue access, reliable synchronisation, recoverable
state, and a model that can preserve conflicting edits rather than silently
overwriting them.

## Decision

Bookish represents durable changes as immutable, write-once mutation records.
The mutation history is the canonical write and synchronisation unit.

The application maintains a materialised record store as a fast local projection
of that history. The record service exposes reads, queries, relationships, and
observation to application clients. The mutation service owns semantic writes,
outbox management, remote mutation application, dependency handling, conflict
handling, and projection updates.

The user interface reads through the record service and never writes directly
to either the record store or mutation store.

## Consequences

- The record projection can be rebuilt from mutation history.
- Writes can be applied optimistically and retried idempotently.
- Out-of-order remote mutations can remain pending until their dependencies are
  available.
- Conflicts remain representable for deliberate resolution.
- Import/export uses storage-neutral record snapshots; mutation history is a
  separate diagnostic or archive concern.
