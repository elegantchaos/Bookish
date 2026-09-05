# Datastore Design

The persistent database is a low level key/value store, consisting of records with named properties, containing storage-neutral property values.

A fast record store is kept on device. Cloud syncing is handled by CloudKit, with Bookish storing and exchanging write-once mutation records through CloudKit.

Records are untyped, and can be linked unidirectionally to form a graph.

Semantic meaning is assigned to the database records by higher-level layers. These layers use conventions to ascribe types to records, to manage bi-directional and many-to-many links, to manage record lifecycles, etc. 

## Terminology

- A **mutation record** is an individual atomic, write-once mutation.
- The **mutation store** is the on-device durable store of known mutation records, including local outbox state, applied mutations, pending dependencies, and indexes needed for processing.
- The **mutation service** provides the write API used by command-driven application actions, maintains the mutation store, interacts with CKSyncEngine, applies incoming mutations, detects conflicts, and updates the record store.
- A **record** is a single on-device key/value record.
- The **record store** is the projected cache of materialised records used by the application and user interface.
- The **record service** provides the read/query/observation API used by the user interface, backed by the record store.
- A **CloudKit record** refers specifically to a CloudKit `CKRecord`.

## CloudKit Sync

CloudKit is the proposed sync mechanism for the initial design. Bookish relies on CloudKit and CKSyncEngine for remote change delivery, scheduling, account handling, retry behaviour, and sync state.

The Bookish data synced through CloudKit is a list of mutation records. CloudKit manages transport and storage mechanics; Bookish defines the meaning of each mutation, its identity, its parent relationships, and how it is applied to the record store.

Mutation types consist of:
- setting a property of a record to a value;
- removing a property by assigning it a deletion value;
- inserting an entry into an ordered list property;
- removing an entry from an ordered list property;
- moving an entry within an ordered list property.

Whole-list replacement is acceptable for import, export, or bootstrapping. Normal user edits should use list-entry mutations so independent list changes do not unnecessarily conflict with each other.

New records are created automatically the first time a property is assigned a value.

Records are tombstoned rather than deleted. Record deletion is represented by a reserved boolean property. Property deletion is represented by a reserved deletion value in the mutation stream; the record store can materialise that as the property being absent.

Mutation records consist of:
- identifier
- operation kind
- target record
- target property
- list entry identity and ordering information, where relevant
- value, where relevant
- parent identifiers
- creation metadata

Each device participating in sync is assigned a UUID, which it persists locally. 

Each mutation record is assigned an identifier, composed of the device identifier followed by an integer mutation index. This index is unique to the device.

Bookish mutation identifiers are kept even though CloudKit also identifies CloudKit records, because the Bookish identifiers are used for parent links, idempotency, and conflict resolution.

The parent identifiers of a mutation record are the identifiers of the mutation records that set the previous value for the affected property or list entry. Normally there is only one parent, but in the case of a conflict there may be more.
 
Mutation records are write-once, and will never clash.

The unique identifier for a specific device may change over time - for example if the user deletes then re-installs the app. Therefore the id is not a mechanism for tracking the device; it exists solely to ensure uniqueness of mutation records.

Aggregate mutation records may be used as envelopes for transport or storage efficiency. Each logical mutation inside an aggregate still has its own identity and parent identifiers.
 
## Device

On device, a fast record store is maintained.

The record store should be fast enough to efficiently supply an observable record, with all properties materialised, including links to other records, for use by the user interface.

The user interface reads from the record store. When the user initiates changes to the database, they are converted into mutation records. These mutation records are durably stored in the mutation store's local outbox before being applied optimistically to the record store and sent through CloudKit.

The record service exposes record store reads and observations to the user interface. The mutation service is the only service that performs durable semantic writes, including local user edits and remote sync changes.

Unsent mutations remain in the outbox until CloudKit confirms them. Sending is idempotent because mutation identifiers are stable. Failed or delayed sends are retried without rolling back the record store unless the mutation itself is rejected as invalid.

Incoming mutation records may arrive in any order and from any device. The mutation store tracks applied mutation identifiers and holds mutation records with missing parents as pending dependencies. A mutation record is applied once its required parents are present, or deliberately treated as absent during recovery or import. Per-device sequence numbers are useful for identity and diagnostics, but are not the primary replay mechanism.

Given the full history of mutation records, the record store can be reconstructed at any time.

The app may discard an unreadable record projection during startup and rebuild it
from the mutation store. The development menu also provides the same rebuild
operation. A separate destructive reset removes both the projection and mutation
history.


## Conflicts

Each record property in the record store records the current value, and the mutation head or heads that determine the value.

When a local mutation occurs, the current mutation heads for the affected value are used as the parents of the mutation record.

When a remote mutation record is received, if its parent identifiers do not match the record store's recorded heads for the affected value, a conflict has occurred.

In this situation a new mutation is created which resolves the conflict. Both of the conflicting mutation records are used as parent identifiers for the new one. 

If both parents had the same value, the new mutation record just uses it.

Otherwise, the new mutation record stores a special conflict value containing both alternatives. The user interface presents this to the user and asks them to choose. The ordering is based on the sort order of the parent identifiers, and is therefore deterministic.

List-entry mutations parent the relevant entry or ordering heads rather than the whole list value. This allows independent list edits to merge without forcing a conflict across the entire list.

## Values
Property values are represented by an enumeration with the current set of cases:
- primitives (string, int, uint, double, bool)
- encoded values: small Codable values encoded as opaque JSON payloads
- a reference to another record
- a reference to a blob file
- ordered lists of property values
- deletion markers
- conflict markers

The following rule of thumb was used to determine these cases, and should be used in the future when adding new value cases:
- Add a case for types representable as a primitive JSON value, such as an integer, string, number, boolean, lists.
- Add a case for datastore plumbing such as record and blob references, tombstones, deletion markers, conflicts, etc.
- Use the encoded case for small Codable value for other self-contained values with domain-specific semantics, such as dates or URLs.

### Compound Values
Compound values (eg structs or classes) can be represented in two ways:
- an encoded struct
- a reference to another record containing the properties of the compound

The rule of thumb when deciding which approach to use is similar to the one for cases. 
If the struct is small, and the value is used for internal plumbing, or not likely to be surfaced as individual fields in the user interface, it can be stored as an encoded value.
If the value is large, is likely to be used to build a data-driven user interface where individual properties of the value are extracted or displayed individually, it is better to store it as a reference to another record.
If the value represents a dictionary, it should also be represented as a link to a record (with that record in turn linking to other records if the dictionary is multi-level).
Small encoded values are useful but they do not fully participate in all of the datastore mechanisms. An edit to a single field in one of these values changes the whole value, so the probability of conflicts is higher. There is also more potential for their representation to end up opaque in an interchange file - depending on how they are encoded. For discoverability and integration with tools, it's generally preferable to be able to represent values in a way that translates to/from JSON dictionaries naturally.
Encoded values do not need explicit application-level type tags - eg when represented as JSON. The application layer is expected to know what kind of value it expects for a property, and decode or coerce the stored value into that type. This operation can fail if the value does not match the expected type. Having said that, an encoded value can include a type hint. This can be used by a decoder to determine the type to create.

## Large Blob Data

Large binary payloads should be stored out-of-line and treated as immutable. Property values should refer to these payloads using blob references rather than storing the data directly.
A blob reference should identify the blob and include lightweight metadata such as checksum, byte count, media type, or original filename when useful.
CloudKit can store and synchronise blob payloads using CloudKit assets. A mutation record can then set a property to a blob reference, while the referenced blob payload is stored separately from the mutation record itself.

Replacing blob data means creating a new blob payload and updating the property to point at the new blob reference. Existing blob payloads should not be modified in place.

For the initial design, blob payloads are not automatically removed. A blob should be considered live if it is referenced by any current record property, conflict value, pending mutation, unapplied mutation, or local outbox item.

If a blob upload fails, the local blob payload should be retained because it may be the only remaining copy of the data. Blob upload state should be tracked as service metadata rather than embedded in the user-facing blob reference value, and exposed through service APIs so the user interface can alert the user.

Blob cleanup can be introduced later through an explicit database compaction or unused-blob cleanup command. Full snapshot and compaction support can also remove blobs that are provably unreferenced after old mutation history has been pruned or archived.

## Record Links

The record database can form a graph, using record properties which contains record links, or ordered lists of record links.

Some links between records require metadata describing the connection between the linked records.

Rich links can be represented as relationship records. For example, a contributor relationship can carry the contributor's role, credited-as name, and source-specific notes alongside references to the book and person.

High-level clients can use combinations of:
- simple record links;
- ordered lists of links;
- links or lists of links to relationship records; and
- composite relationship records containing common metadata and ordered lists of members.

Implementation choices and follow-up design work are tracked in `Datastore Implementation.md`.

## Appendix A: Storage Options Considered

The initial implementation should use SQLite directly for the mutation store and record store. The model needs simple append-only writes, durable outbox state, indexed dependency lookups, and materialised record tables. Raw SQLite keeps dependencies low and avoids adding a model framework around what is essentially a small set of purpose-built tables.

SQLiteData is a modern SwiftData-like layer over SQLite, with query observation and CloudKit support. It is built on GRDB, so it does not avoid that dependency. It may be worth revisiting for the record store if SwiftUI query observation becomes a major source of boilerplate, but its CloudKit support should not be used for the mutation store because Bookish owns the sync protocol.

GRDB is a mature Swift SQLite toolkit. It remains a good fallback if direct SQLite access becomes too verbose or error-prone, but it is not required for the initial design.

FMDB is an older Objective-C SQLite wrapper. Its useful ideas are serialized database access, transaction helpers, parameter binding, and optional SQLCipher support. It is useful background, but it is not the preferred dependency for new Swift code.

PARStore is useful prior art for a key/value store with device-specific logs, a materialised in-memory view, and one-way data flow between log storage and the current key/value state. Bookish borrows the architectural idea, but not the implementation.

The older ElegantChaos Datastore package is also useful prior art for an asynchronous schema-less object store with property-level history. Its Core Data-backed implementation and entity/property model are not the adopted design, but several ideas are worth retaining: async-only access, bulk operations, lightweight references, on-demand reference resolution and creation, partial result objects, and JSON-legal interchange.

Storage references:
- https://www.sqlite.org/docs.html
- https://github.com/pointfreeco/sqlite-data
- https://github.com/groue/GRDB.swift
- https://github.com/ccgus/fmdb
- https://github.com/cparnot/PARStore
- https://github.com/elegantchaos/Datastore

## Appendix B: CRDT Notes

This plan is not a full CRDT design. It uses write-once mutation records with causal parent links, plus deterministic conflict detection and resolution.

Scalar conflicts are preserved as conflict values for user or application resolution rather than automatically merged. Ordered list and link operations may borrow CRDT-style ideas where they improve practical conflict behaviour, but only for specific property kinds.

Full CRDT adoption is not justified for the initial design because expected use is light, mostly single-user, and conflicts should be rare. The model should remain compatible with adding CRDT-style value semantics later if particular property types need them.

CRDT references:
- https://github.com/appdecentral/replicatingtypes
- https://github.com/heckj/crdt

## Appendix C: Snapshot And Compaction

Snapshots and compaction are not required for normal startup in the initial design, because the record store is the working projection.

A later snapshot mechanism can provide faster rebuild and recovery by recording a materialised database state at a known mutation frontier. 

Compaction can then prune or archive old mutations after a safe snapshot boundary, reducing the danger of database bloat.

Compaction can also remove blob payloads that are provably unreferenced by the current record store, retained conflicts, pending mutations, unapplied mutations, or local outbox items.

The initial design should keep mutation store and record store metadata structured enough that snapshots and compaction can be added without changing the app-facing model.

## Appendix D: Service Boundaries

The record service and mutation service deliberately split reads from writes. The record service is a read facade over the record store. It supports queries, record lookup, relationship traversal, list materialisation, and observation for the user interface.

The mutation service owns durable semantic writes. Local app actions call the mutation service to create mutation records. CloudKit delivers remote mutation records to the mutation service. The mutation service validates dependencies, records outbox or applied state in the mutation store, resolves or records conflicts, and updates the record store.

The record service should not write to the mutation store or initiate sync. The user interface should not write directly to the record store. The record store can have internal write APIs, but those should be used by the mutation service or by rebuild/import tooling that applies mutation records in the same way.

The mutation service does not need to own the record service. Both services can share lower-level storage components, or be composed behind a single app-level facade. The important dependency direction is that mutations update the record store, and record service observations publish the resulting materialised state.
