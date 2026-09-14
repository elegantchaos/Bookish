# 2026-09-14 Decision Log Backfill

Created `Extras/Decisions/` and recorded the established Bookish decisions that
were previously distributed across design documents and journal entries.

The initial decision set covers the command boundary, mutation-log projection,
schema-less record graph, metadata-driven data views, shared record model,
interchange documents, retained import source snapshots, review-first cleanup,
record identity and representation, and the application-neutral Datastore
boundary.

The Datastore sync transport is explicitly provisional: CloudKit and
`CKSyncEngine` are the current proposed choice, while Datastore retains its own
application-neutral mutation and projection contracts.

Deferred candidates include configuration seed lifecycle, recognition-provider
semantics, and the local storage implementation choice. They are not recorded
as decisions because they remain emergent or require further confirmation.
