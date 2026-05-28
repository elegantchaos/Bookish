# Datastore Implementation

This document tracks implementation choices for the datastore design in `Datastore Design.md`. These are build-time decisions rather than unresolved product direction.

## Implementation Defaults

- Use CKSyncEngine directly for CloudKit sync.
- Use raw SQLite initially for the mutation store and record store.
- Keep mutation records as the canonical write/sync unit.
- Keep the record store as a materialised projection maintained by the mutation service.
- Do not use SwiftData, SQLiteData, GRDB, or FMDB for the initial implementation unless raw SQLite becomes too costly.
- Do not implement full CRDT semantics, snapshots, or compaction for the MVP.

## API Shape

Define a small read/write split:
- **Record service**: record lookup, queries, relationship traversal, list materialisation, and UI observation.
- **Mutation service**: user/app mutations, CloudKit sync, outbox management, dependency processing, conflict handling, and projection updates.

The app may compose both behind a convenience facade, but UI code should read through the record service and application actions should write through the mutation service.

Application writes should be requested through the command pattern defined by `elegantchaos/Commands`. Commands should express user intent, availability, validation, and execution, then call the mutation service to create mutation records. UI controls, menus, keyboard shortcuts, import flows, and automation should invoke these commands rather than writing directly to the record store or mutation store.

The earlier Proposal 1 API sketch is worth retaining as inspiration for a small facade: record lookup, query, observe, transact, import, and export.

The older ElegantChaos Datastore API is worth retaining as prior art for async-only access, bulk operations, lightweight references, on-demand creation, and partial result objects. These ideas should be adapted to the mutation service and record service split rather than copied directly.

API references:
- https://github.com/elegantchaos/Commands

## Mutation Store Work

Decide the concrete SQLite schema for:
- mutation records;
- local outbox state;
- applied mutation identifiers;
- pending parent dependencies;
- current mutation heads;
- aggregate mutation envelopes;
- CKSyncEngine state and CloudKit metadata;
- blob upload state;
- schema versioning and migrations.

Decide the concrete mutation representation for local SQLite, CloudKit records, and JSON diagnostics/interchange. It should include operation kind, target record, target property, optional list-entry identity and ordering data, value data, parent identifiers, and creation metadata.

Define the rule for missing parents during recovery and import. Normal sync should keep parentless mutations pending; recovery/import may deliberately treat missing parents as absent only under an explicit policy.

## Record Store Work

Decide the concrete SQLite schema for:
- materialised records;
- materialised properties;
- property value storage;
- record links;
- ordered list entries;
- relationship indexes;
- search indexes;
- blob references;
- mutation heads per materialised value.

Choose the list ordering strategy before implementation. Candidate approaches include relative anchors, fractional order keys, or another stable order key with deterministic tie-breaking.

## SwiftUI And Observation

Decide how SwiftUI views interact with the record service:
- observable record wrappers;
- query/list observation;
- property-level updates;
- relationship and ordered-list updates;
- whether macros or generated helpers are useful.

This work should align with `Data View Design.md`.

## CloudKit Work

Decide:
- private database and custom zone layout;
- CloudKit record types for mutations and blob assets;
- CloudKit record naming from Bookish mutation and blob identifiers;
- batching limits and retry policy;
- handling account/container changes;
- how CKSyncEngine state is persisted and restored;
- how upload failures surface through service APIs.

## Blob Work

Implement immutable out-of-line blob storage.

MVP behaviour:
- blob payloads are retained indefinitely;
- failed uploads keep the local payload;
- upload failures are exposed to the UI through service APIs;
- cleanup is manual or deferred until snapshot/compaction support.

## Conflict Work

Define:
- the stored shape of conflict values;
- conflict resolution mutations;
- user-visible conflict presentation;
- application-level automatic resolution for identical values;
- behaviour when conflicts involve blobs, ordered lists, or relationship records.

## Import, Export, And Interchange

Decide whether export uses:
- materialised records only;
- mutation history;
- snapshots;
- or a combined diagnostic/archive format.

For user-facing import/export, prefer storage-neutral materialised records. For diagnostics and recovery, mutation history may also be useful.

The older ElegantChaos Datastore README mentions compact interchange output that drops older values. In the new design this maps to exporting materialised records, while mutation history remains available for diagnostics, recovery, or archive formats.

## Test Plan

Retain these Proposal 1 test ideas:
- property value encoding and decoding;
- primitive, structured, blob reference, link, list, deletion, and conflict values;
- mutation operations for set, delete, insert, remove, move, tombstone, and restore;
- dependency processing with out-of-order remote mutations;
- conflict detection and resolution;
- outbox retry and idempotent resend;
- record store rebuild from mutation history;
- CloudKit adapter mapping with local fake records before using a real container;
- import/export round trips from fixtures.
