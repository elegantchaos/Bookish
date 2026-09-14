# 0016: Preserve records and blobs through tombstones and immutable references

- Status: Accepted
- Date: 2026-05-28

## Context

Bookish needs destructive actions, synchronisation, recovery, and media storage
to remain reliable even when devices are offline, mutations arrive out of order,
or an upload fails.

## Decision

Records are logically deleted by tombstoning them rather than removing their
identity and history. Property deletion is represented in the mutation stream as
a deletion marker.

A merged record uses a tombstone with a `mergedInto` record identifier referring
to its canonical surviving record. Before that tombstone is applied, the merge
operation rewrites inbound links to the canonical record according to its merge
policy. The merge tombstone retains redirect and provenance information for
diagnostics, recovery, and any remaining historical references.

An ordinary deletion tombstone has no `mergedInto` identifier. Record removal,
restoration, and merge therefore remain distinct semantic operations.

Large binary payloads are stored out-of-line and referenced by immutable blob
references. Replacing blob content creates a new payload and updates the record
property to a new reference; existing payloads are never changed in place.

Blob payloads are retained by default. A blob remains live while referenced by a
current record property, conflict value, pending or unapplied mutation, or local
outbox item. Failed uploads retain the local payload because it may be the only
remaining copy. Automatic blob deletion is deferred until an explicit,
proven-safe compaction or unused-blob cleanup capability exists.

## Alternatives considered

Hard-deleting records was rejected because it weakens recovery, synchronisation,
and reversible user actions. Treating merged records as ordinary deletions was
rejected because it loses their canonical redirect and merge provenance. In-place
blob mutation was rejected because it breaks immutable history and makes content
identity unreliable. Eager automatic blob cleanup was rejected because it can
remove a payload still needed by pending sync, a conflict, or a failed upload.

## Consequences

- Record identity and mutation history survive logical deletion.
- Merge operations preserve an explicit redirect from an absorbed record to its
  canonical replacement after inbound links have been rewritten.
- Media replacement is explicit, traceable, and safe for synchronisation.
- Storage may grow until a future compaction capability proves a payload is
  unreferenced.
- UI and service APIs must expose failed upload state without discarding local
  data.
