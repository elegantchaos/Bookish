# Bookish Persistence Model Plan

The persistent database is a low level key/value store, consisting of records with named properties, containing primitive values.

A fast snapshot is kept locally. Cloud syncing is done via mutation records.

Records are untyped, and can be linked unidirectionally to form a graph.

Semantic meaning is assigned to the database records by higher-level layers. These layers use conventions to ascribe types to records, to manage bi-directional and many-to-many links, to manage record lifecycles, etc. 


## Cloud

The cloud component only stores a list of mutation records.

Mutation types consist of:
- set property P of record X to V
- remove property P of record X

New records are created automatically the first time a property is assigned a value.

Mutation records consist of:
- identifier
- key
- value
- parent identifiers

Each device participating in sync is assigned a UUID, which it persists locally. 

Each mutation record is assigned an identifier, composed of the device identifier followed by a integer mutation index. This index is unique to the device.

The parent identifiers of a mutation record are the identifiers of the mutation record that set the previous value for the given key. Normally there is only one parent, but in the case of a conflict there may be more.
 
Mutation records are write-once, and will never clash.

The unique identifier for a specific device may change over time - for example if the user deletes then re-installs the app. Therefore the id is not a mechanism for tracking the device; it exists solely to ensure uniqueness of mutation records.
 
## Device

On device, a fast record cache is maintained (probably using SwiftData).

The user interface reads from this cache. When the user initiates changes to the database, they are converted into mutations. These mutations are applied directly to the local cache, and also pushed to the cloud.

A service on the local device scans for incoming mutations from the cloud. Mutation records may arrive in any order, and from any device. The local service keeps an index of the latest processed record from each known device. When the next unprocessed mutation in sequence is available from a known device, it is applied to the local record cache, and the index is updated.

Given the full history of mutation records, the local cache can be reconstructed at any time.

The on device cache should be fast enough to be able to efficiently supply a record, with all properties, for use by the user interface.

## Conflicts

Each record property in the local cache records the current value, and the identifier of the mutation record that set the value.

When a local mutation occurs, this identifier is used as the parent of the mutation record.

When a remote mutation is received, if the parent identifier doesn't match the local cache's recorded value, a conflict has occurred.

In this situation a new mutation is created which resolves the conflict. Both of the conflicting mutation records are used as parent identifiers for the new one. 

If both parents had the same value, the new mutation record just uses it.

Otherwise, the new mutation record stores a special conflict value containing both alternatives. The user interface presents this to the user and asks them to choose. The ordering is based on the sort order of the parent identifiers, and is therefore deterministic.

## Values

Property values can be:
- primitives (string, int, double, date, bool)
- codable types
- record references
- ordered lists of the above
- conflict markers

## References

The record database can form a graph, using a record property which contains a record reference, or a list of record references.


## Open Questions

- Does this design have enough history information for clear conflict resolution?
- Is this basically CRDT? If not, what are the differences?
- Can we safely support aggregate mutation records for efficiency (eg a single mutation record could actually include a list of mutations)
- Can we use CloudKit for transferring mutation records. What is the simplest implementation we can get away with? It would be good to avoid redundant information in the mutation records - eg a CK-managed identifier and our own. Can we leverage anything from CK?
- Should we use SwiftData for the local record cache? Might a simple directory/file structure be more efficient, with in-memory copies of records? Since records are schema-less, SwiftData may not be the best fit. Are there any other third party options? 

Possible references:
- https://github.com/pointfreeco/sqlite-data
- https://github.com/groue/GRDB.swift
- https://github.com/appdecentral/replicatingtypes
- https://github.com/heckj/crdt
