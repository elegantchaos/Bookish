# 2026-09-25 Stable Mutation Order

`JSONMutationStore.mutations()` sorts by `createdAt`, then by mutation ID.
The JSON coders used `.iso8601` dates, which drop fractional seconds. In memory
the order was correct. After a reload, mutations created in the same second
tied and fell back to UUID order. `rebuildRecordProjection` could then replay
two edits to one record in the wrong order. The import audit list work on
`feature/importer-improvements` exposed this when an import wrote two records
in one batch.

## Requirement

Devices need not agree with each other, but once devices are fully synced, a
reset on any of them must produce the same projection. Replay order must
therefore be a function of the synced mutation data alone. `(createdAt, id)`
already is; the defect was the encoder discarding precision.

## Approaches

- A local append sequence stored in an envelope around each mutation file was
  implemented first and then dropped. After a reset, append order is sync
  delivery order, so fully synced devices could rebuild different projections.
- Fractional-second ISO8601 was rejected. Foundation keeps only milliseconds,
  and an import batch can create several mutations within one.
- Adopted: the datastore coders now use `.deferredToDate`, writing dates as
  raw reference-date intervals that round-trip exactly. Mutation records are
  not user-facing, and a CloudKit implementation will not use this JSON
  encoding, so readable timestamps are not needed. `createdAt` is the only
  date these coders handle; record date values are pre-encoded by
  `BookishRecord`'s own coder.

## Strictly increasing creation dates

`MutationStore.nextCreationDate()` returns `max(now, latest.nextUp)`, where
`latest` is the latest date the store has issued or stored, including remote
mutations. `DefaultMutationService.perform` stamps local mutations with it.
Local edits therefore sort after everything the device has seen, even if the
wall clock steps backwards or a remote device's clock runs ahead. The store
actor serialises issue, so concurrent performs also get distinct dates.

Recorded as [Decision 0023](../Decisions/0023-mutation-creation-time-ordering.md),
framed as a mutation design rule: creation time is part of the synced mutation
data, and with the identifier it totally orders any set of mutations.

Clock skew between devices still decides which of two concurrent edits wins,
but every device decides the same way. Parent-based replay from the Datastore
Design can refine this later.

No compatibility path exists for mutation files with ISO8601 dates; by
agreement, existing development stores are reset or re-imported.

## Tests

- `mutationStorePreservesSubMillisecondCreationOrderAcrossReload`: four
  mutations 0.1 ms apart with IDs in reverse lexical order survive a reload in
  creation order.
- `performedMutationsKeepCreationOrderAfterRebuild`: twenty rapid edits to one
  record rebuild to the last value after a reload.
- `mutationStoreCreationDatesStrictlyIncrease` and
  `mutationStoreCreationDatesFollowLatestStoredMutation` cover the clock.

The first two fail with the old `.iso8601` strategy.

## To revisit: mutation identifiers

The Datastore Design describes mutation identifiers as a device identifier
followed by an integer mutation index. The implementation uses `UUID()`. Decision
0023 only needs identifiers to sort identically on every device, which both
forms do, but the two should be reconciled.

A UUID may be enough on its own. Note that Foundation's `UUID()` is version 4
and entirely random, so it carries no device component; a device-derived form
would need a time-based UUID or an explicit prefix. The device-plus-integer
scheme also gives sequential identifiers from a given device within a session,
which may be worth having regardless, for diagnostics, for detecting gaps, and
as a natural tie-break between mutations from one device.
