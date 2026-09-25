# 0023: Give mutations a precise, strictly increasing creation time

- Status: Accepted
- Date: 2026-09-25
- Refines: [Decision 0002](0002-mutation-log-and-record-projection.md) on rebuilding the projection from mutation history
- Refines: [Decision 0010](0010-application-neutral-datastore.md) on the contracts a sync transport must preserve

## Context

[Decision 0002](0002-mutation-log-and-record-projection.md) makes the mutation
history canonical and the record store a projection that can be rebuilt from it.
It does not say what order a rebuild uses. Devices do not need to agree with each
other at every moment, but once devices hold the same mutation history, a reset
on any of them must produce the same projection.

The first JSON mutation store sorted by creation time, then identifier, but
encoded dates as whole-second ISO8601 strings. Mutations created in the same
second fell back to identifier order after a reload, so two edits to one record
could replay in the wrong order.

The Datastore Design orders causally related mutations through parent
identifiers and represents concurrent edits as conflict values. Parents are not
yet recorded, and they cannot order mutations that are not causally related.

## Decision

Every mutation record carries a creation time as part of its immutable, synced
data. The creation time:

- is kept at full precision wherever mutations are stored or transported;
- is strictly increasing for local mutations on each device, and later than
  every mutation the device has already stored, including remote ones, even if
  the wall clock steps backwards.

A mutation's creation time and identifier together give a deterministic total
order over any set of mutations. That order is a property of the mutation data
alone; local state such as arrival order, append order, or per-device counters
never decides the projection.

The mutation service orders application by parents where they exist, and by
creation time, then identifier, wherever parents do not already decide.
Concurrent edits with competing parents still become conflict values as the
Datastore Design describes. Until parents are recorded, creation time and
identifier alone determine replay order.

## Alternatives considered

- **Local append sequence.** Rejected. After a reset, append order is whatever
  order sync delivered, so devices with the same history could rebuild
  different projections.
- **Millisecond-precision timestamps**, such as fractional-second ISO8601.
  Rejected. A single import batch can create several mutations within one
  millisecond.
- **Parent identifiers alone.** Retained as the causal mechanism and
  conflict model, but not sufficient on its own: parents cannot order unrelated
  mutations and are not yet implemented.
- **Hybrid logical clocks or explicit per-device counters in the sort key.**
  Deferred. The strictly increasing local clock already gives the needed
  per-device guarantee; these remain options if clock behaviour proves
  inadequate.

## Consequences

- Any device holding the same mutation history rebuilds the same projection.
- Local edits sort after everything the device had seen when they were made.
- Clock skew between devices decides which of two unrelated edits sorts later,
  but every device decides the same way.
- Storage and sync adapters must round-trip creation times exactly. The JSON
  local stores encode dates as raw reference-date intervals. A CloudKit adapter
  must not rely on a date field that loses precision.
- Mutation stores provide the next local creation time, because they know the
  latest creation time they hold.
- Existing development mutation files with ISO8601 dates are not migrated.
