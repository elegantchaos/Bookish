# 0010: Keep Datastore application-neutral

- Status: Accepted, provisional transport choice
- Date: 2026-05-28

## Context

Bookish needs a local-first datastore with durable mutation history, projected
records, and synchronisation. The datastore is being developed alongside
Bookish, but its record and mutation model is intended to remain useful as a
standalone, application-neutral package.

## Decision

`Datastore` owns application-neutral record persistence, immutable mutation
history, materialised record projection, outbox state, dependency processing,
idempotency, and conflict representation. It does not own Bookish catalogue
semantics, SwiftUI presentation, or importer-specific source interpretation.

Bookish integrates with Datastore through its record and mutation service
boundaries, and supplies its own catalogue conventions and application actions.

CloudKit with `CKSyncEngine` is the current proposed synchronisation transport.
It provides remote storage, change delivery, account state, scheduling, and
transport retry behaviour. Datastore retains ownership of mutation identity,
causal relationships, validation, and projection application.

The transport choice is intentionally replaceable. A later evaluation may retain
the Datastore model and service boundaries while replacing or supplementing the
CloudKit adapter.

## Alternatives considered

Making CloudKit records the catalogue model was rejected because it would couple
Datastore’s mutation and projection semantics to one transport. CloudKit with
`CKSyncEngine` is the current proposed adapter, not an irreversible commitment;
other transports may be evaluated while preserving Datastore’s application-neutral
contracts.

## Consequences

- Datastore can evolve toward a standalone package without inheriting Bookish
  domain or UI dependencies.
- Bookish does not treat CloudKit records as its catalogue model.
- The current CloudKit implementation path is documented without making it an
  irreversible architectural commitment.
- A replacement transport must preserve Datastore’s mutation, recovery, and
  conflict contracts.

## Related research

DynamoDB and Firestore are persistent NoSQL key/value systems with concerns that
overlap Datastore’s scope. They are useful design references for later research,
not adoption candidates or dependencies. Their approaches may inform the
Datastore design without changing its application-neutral boundary.
