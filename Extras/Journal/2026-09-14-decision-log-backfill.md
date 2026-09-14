# 2026-09-14 Decision Log Backfill

Created `Extras/Decisions/` and recorded the established Bookish decisions that
were previously distributed across design documents and journal entries.

The initial decision set covers the command boundary, mutation-log projection,
schema-less record graph, metadata-driven data views, shared record model,
interchange documents, retained import source snapshots, review-first cleanup,
record identity and representation, and the application-neutral Datastore
boundary.

Also recorded the modern Apple-platform technology baseline: Swift 6.4 or
later, SwiftUI, modern Swift concurrency, Swift Testing, and macOS/iOS support
including iPhone and iPad. The current 26.0 deployment target is expected to
move to 27.0 before release, while Foundation Models remains runtime-optional.

The package-first architecture is also recorded: Bookish has a thin Xcode host,
local SwiftPM packages, and selectively co-developed Elegant Chaos submodules.
The local workspace override of released package requirements is deliberate but
temporary; each shared package must later be integrated, released, and restored
to an independently buildable version requirement.

The Datastore sync transport is explicitly provisional: CloudKit and
`CKSyncEngine` are the current proposed choice, while Datastore retains its own
application-neutral mutation and projection contracts.

Deferred candidates include configuration seed lifecycle, recognition-provider
semantics, and the local storage implementation choice. They are not recorded
as decisions because they remain emergent or require further confirmation.
