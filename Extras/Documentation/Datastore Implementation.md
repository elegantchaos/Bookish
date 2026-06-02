# Datastore Implementation

This document tracks implementation choices for the datastore design in `Datastore Design.md`. These are build-time decisions rather than unresolved product direction.

## Proof Of Concept

We will start by building out a proof-of-concept prototype, as a macOS SwiftUI application, and some SwiftPM packages, added to the Bookish project.

We will need the following targets:
- DatastorePrototypeApp: added to the Bookish xcode project as a SwiftUI app target
- BookishRecord: the shared materialised record model used across datastore, import, coding, and presentation boundaries
- BookishDatastore: the datastore proof-of-concept package
- BookishRecordView: the SwiftUI record presentation proof-of-concept package
- BookishCoding: JSON interchange coding for `BookishRecord`
- BookishImporterNu: the new importer prototype that emits normalised `BookishRecord` graphs

The prototype should implement the following minimal functionality:

- enough of the record store to define and store records locally
- enough of the mutation store to define and store mutations locally
- enough of the mutation service to apply mutations to the record store
- enough of the record service api to fetch one or more records and supply them to a record view
- a prototype RecordView which is supplied with a `BookishRecord` to display and a `BookishRecord` representing the layout to display it with
- a simple app harness which initialises the services, creates test records, views them with a RecordView, and allows us to manipulate the data by creating and processing mutations
- unit tests for each individual package 
 
The initial prototype need not:
 - implement real syncing via CKSyncEngine (we can have a temporary api to simulate arrival of remote mutations)
 - implement database storage with SQLite (we can use simple json encoding and file-based storage for easy debugging)
 
The code may end up being a disposable prototype, but it should be written following all of our guidelines. It may not be
dispoable, and should be treated as potentially the first evolution of the eventual codebase. 

Protocols or stubs for missing functionality should be created in a way that allows them to be replaced with the real implementations later. Initial test implementations should use the same protocols (or base classes), so that they can continue to work alongside the final implementation (for example, for integration tests). 

## Current Prototype Boundary

The prototype now uses `BookishRecord` as the shared materialised record type across package boundaries:

- `BookishRecord` owns `BookishRecordID`, `BookishRecord`, `BookishRecordValue`, and `BookishBlobReference`.
- `BookishDatastore` owns mutation records, record/mutation stores, and datastore services, but imports record identity and property values from `BookishRecord`.
- `BookishRecordView` imports `BookishRecord` directly for record presentation, and imports `BookishDatastore` only for mutation presentation.
- `DatastorePrototypeApp` uses `BookishRecord` values in its observable harness and selection model.
- `BookishCoding` provides the storage-neutral JSON interchange codec for `BookishRecord` graphs.
- `BookishImporterNu` returns provider-neutral import results containing `BookishRecord` graphs.

The legacy `BookishCore`, legacy `BookishImporter`, and main `BookishApp` import path remain unchanged during this migration.


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

Record service APIs should expose `BookishRecord`, `BookishRecordID`, and `BookishRecordValue` rather than datastore-private record representations. This keeps persistence providers black-box while allowing import, lookup, scanning, commands, business logic, and UI code to share a single materialised record shape.

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

User-facing import/export uses storage-neutral materialised records encoded by `BookishCoding`. The current interchange file contains a format marker, schema configuration, optional root record identifier, and an array of `BookishRecord` snapshots.

The default interchange schema uses:

- `idKey = "id"`
- `kindKey = "kind"`
- `defaultKind = "record"`
- `rvKey = "®"`

Record decoding reads `id` and `kind`, then treats every remaining key as a property. Canonical record links encode as `{ "®": "record", "id": "record-id" }`. Compact JSON decoding accepts primitive JSON values where unambiguous and strict `@record-id` shorthand for links. Compact link encoding is opt-in and remains a JSON-only codec convenience.

`BookishImporterNu` imports Delicious Library XML into a normalised graph rather than a flat book-only output. It emits book, person, organisation, series, relationship, and root list records with deterministic IDs.

For diagnostics and recovery, mutation history may also be useful, but that should be a separate diagnostic/archive format rather than the default user-facing interchange format.

The older ElegantChaos Datastore README mentions compact interchange output that drops older values. In the new design this maps to exporting materialised records, while mutation history remains available for diagnostics, recovery, or archive formats.

## Test Plan

Retain these Proposal 1 test ideas:
- property value encoding and decoding;
- primitive, structured, blob reference, link, list, deletion, and conflict values;
- JSON interchange canonical and compact encoding/decoding through `BookishCoding`;
- Delicious import graph normalisation and interchange round trips through `BookishImporterNu`;
- mutation operations for set, delete, insert, remove, move, tombstone, and restore;
- dependency processing with out-of-order remote mutations;
- conflict detection and resolution;
- outbox retry and idempotent resend;
- record store rebuild from mutation history;
- CloudKit adapter mapping with local fake records before using a real container;
- import/export round trips from fixtures.
