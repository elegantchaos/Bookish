# Bookish Persistence Model Plan

## Summary

Plan the v1 persistence model as a Bookish-owned record store with CloudKit sync, CRDT-inspired conflict metadata, and a replaceable local projection cache. Default choice: do not make SwiftData or CRDT documents the source of truth; use them only as optional implementation details.

Research anchors: Apple [`CKSyncEngine`](https://developer.apple.com/documentation/cloudkit/cksyncengine), CloudKit [record conflict keys](https://developer.apple.com/documentation/cloudkit/record-changed-error-keys), Apple’s [CKSyncEngine sample](https://github.com/apple/sample-cloudkit-sync-engine), elegantchaos [Datastore](https://swiftpackageregistry.com/elegantchaos/Datastore), [Automerge Swift](https://swiftpackageindex.com/automerge/automerge-swift), [heckj/CRDT](https://swiftpackageindex.com/heckj/CRDT), and the Mental Faculty [Replicating Types series index](https://mentalfaculty.com/blog/).

## Key Design Choices

- Use a minimal app-facing `BookishStore` API:
  - `record(id:)`, `records(matching:)`, `observe(_:)`, `transact(_:)`, `export(_:)`, `import(_:policy:)`.
  - Inputs and outputs use storage-neutral value types: `RecordID`, `RecordKey`, `RecordValue`, `RecordSnapshot`, `RecordQuery`, `RecordMutation`, `RecordChangeBatch`.
- Treat every user edit as a mutation against records/properties/links, not as direct storage writes.
- Model links as records with references and metadata, matching the revised spec.
- Keep deletion as a tombstone mutation: records are marked deleted, not physically removed during normal app operation.
- CloudKit support is mandatory, implemented through `CKSyncEngine`; the store persists sync-engine state and CloudKit record metadata locally.
- Maintain a fast local projection cache for UI queries and indexes. SwiftData is allowed as one cache backend, but the app must not rely on SwiftData as the canonical store.

## Interchange And Conflict Model

- Define a versioned JSON interchange document:
  - top-level `format`, `version`, `created`, optional `root`, and `records`.
  - each record has `id`, `deleted`, `properties`, optional `metadata`.
  - property values are explicitly tagged where needed: primitive, date, data/blob reference, record reference, array, object.
- Use the same interchange value model for import/export, tests, and sync payload conversion.
- Store property-level edit metadata: author/device id, logical timestamp or monotonic revision, previous revision, and operation id.
- Default merge policy:
  - non-overlapping record/property changes merge automatically.
  - collection/link changes use add/remove operations rather than overwriting whole arrays.
  - same-property scalar conflicts preserve both values and create a conflict marker for later UI review.
- Use CRDT ideas selectively:
  - OR-set/add-wins semantics for links and list membership where appropriate.
  - LWW register only for low-value scalar fields where silent overwrite is acceptable.
  - avoid full Automerge-style document storage for v1 unless later research proves the catalogue behaves like collaborative document editing.

## Options And Tradeoffs

- **CloudKit operation/property store, recommended**
  - Pros: fits CloudKit, keeps API small, supports offline edits, gives deterministic conflict handling, avoids binding the model to SwiftData.
  - Cons: more custom infrastructure than automatic SwiftData sync.
- **Revive elegantchaos/Datastore**
  - Pros: already close to the desired schema-less entity/property model and property-versioning idea.
  - Cons: older Core Data-backed package; likely needs modernization before it can be a primary dependency.
- **Full CRDT document store**
  - Pros: strong eventual convergence and mature options like Automerge Swift.
  - Cons: higher conceptual and storage cost; conflicts are hidden inside CRDT semantics; may be excessive for catalogue metadata.
- **SwiftData projection cache**
  - Pros: good UI query ergonomics and Apple-supported local storage APIs.
  - Cons: cache invalidation and bidirectional writes must be carefully controlled; SwiftData CloudKit sync should not be mixed with the custom CloudKit source of truth.

## Test Plan

- Unit-test `RecordValue` encoding/decoding for primitives, dates, nested objects, arrays, references, and unknown future tags.
- Unit-test mutations: set property, remove property, create link, reorder list membership, tombstone, restore.
- Unit-test merge cases: disjoint edits, same scalar edit conflict, concurrent link add/remove, tombstone versus edit, import over existing record.
- Integration-test a fake `BookishStore` implementation against the app-facing API.
- Integration-test CloudKit adapter mapping with local fake records before using a real container.
- Add fixture-based round-trip tests: legacy/import records -> interchange -> store -> export -> equivalent interchange.
- Add cache projection tests proving query/index output updates after local commits and remote change batches.

## Assumptions

- v1 targets iOS and macOS with CloudKit private database sync.
- The source of truth is Bookish’s record/mutation model, not SwiftData.
- SwiftData may be used as a disposable local projection cache.
- CRDTs are a design tool for selected value types, not the whole persistence model by default.
- Datastore should be evaluated as prior art and possible code reuse, but not adopted until its current implementation and Swift 6 readiness are reviewed.
