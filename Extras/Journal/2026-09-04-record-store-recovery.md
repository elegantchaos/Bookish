# Record Store Recovery

## Recovery Contract

The record store is a materialised projection. The mutation store remains the
durable source of truth, so the projection can be discarded and rebuilt by
clearing applied markers and replaying every stored mutation.

## Implementation

`BookishDatastore.rebuildRecordProjection(directoryURL:)` removes the current
record projection, including the legacy projection file, preserves mutations,
and rebuilds the projection from the full mutation history. `BookishHarness`
uses it automatically if opening the record store fails during startup.

The `Rebuild Record Store` menu command invokes the same operation. `Reset
Bookish Datastore` remains destructive: it removes both records and mutations,
then restores configuration seed records.

## Validation

Focused Swift Testing suites passed for BookishDatastore and BookishApp. The
tests cover replaying applied mutations, startup recovery from invalid record
JSON, the rebuild command, and destructive reset behavior.
