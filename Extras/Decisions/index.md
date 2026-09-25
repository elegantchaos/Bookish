# Decision Index

The decision files are the authoritative records. This table summarises their
current status and points out later refinements or supersessions without
rewriting the original decisions. Entries are ordered by decision number.

| Decision | Summary | Status and later changes |
| --- | --- | --- |
| [0001 Engine command boundary](0001-engine-command-boundary.md) | The engine owns services and command execution; views use the commander. | Accepted. [0022](0022-service-state-api-and-provider-shape.md) refines view injection and command access. |
| [0002 Mutation log and record projection](0002-mutation-log-and-record-projection.md) | Immutable mutations are canonical; the record store is a materialised projection. | Accepted; [0023](0023-mutation-creation-time-ordering.md) defines the order used to rebuild it. |
| [0003 Schema-less record graph](0003-schema-less-record-graph.md) | Catalogue concepts are conventions over linked, flexible records. | Accepted. |
| [0004 Metadata-driven data views](0004-metadata-driven-data-views.md) | Configuration records define browser indexes, layouts, and presentation fallbacks. | Accepted. |
| [0005 BookishRecord boundary](0005-bookish-record-module-boundary.md) | Import, storage, presentation, and commands share the storage-neutral record model. | Accepted. |
| [0006 Versioned JSON interchange](0006-versioned-json-record-documents.md) | Interchange uses versioned JSON snapshots and explicit tagged values where needed. | Accepted. |
| [0007 Imported source snapshots](0007-preserve-imported-source-snapshots.md) | Importers preserve accepted source data in `originalData`. | Accepted. |
| [0008 Review-first cleanup](0008-review-first-data-cleanup.md) | Cleanup proposes evidenced changes and checks freshness before applying them. | Accepted. |
| [0009 Record identity and display](0009-record-identity-and-default-representation.md) | Stable `id`, persisted `name`, optional `image`, and kind metadata define identity and defaults. | Accepted. |
| [0010 Application-neutral Datastore](0010-application-neutral-datastore.md) | Datastore owns persistence and mutation machinery without Bookish semantics. | Accepted; CloudKit transport remains provisional. [0023](0023-mutation-creation-time-ordering.md) adds full-precision creation times to the transport contract. |
| [0011 Apple-platform baseline](0011-modern-apple-platform-baseline.md) | Bookish uses modern Swift, SwiftUI, Swift Testing, macOS, and iOS. | Accepted; minimum deployment targets remain provisional. |
| [0012 Thin host and packages](0012-thin-host-and-package-first-architecture.md) | The app target assembles package-owned features and uses local overrides during coordinated development. | Accepted. |
| [0013 Commands as actions](0013-commands-as-application-action-abstraction.md) | Commands own application actions, availability, execution, and undo semantics. | Accepted; [0022](0022-service-state-api-and-provider-shape.md) names the narrow command-centre surface `Access`. |
| [0014 Narrow service capabilities](0014-narrow-command-providers-and-services.md) | Commands depend on focused capabilities and views dispatch domain actions through commands. | Accepted in part. [0022](0022-service-state-api-and-provider-shape.md) supersedes its service-vending and read-only view-interface descriptions. |
| [0015 Record-value representations](0015-record-value-representation-policy.md) | Primitive, tagged, plumbing, and linked-record values serve different semantic scopes. | Accepted. |
| [0016 Tombstones and immutable blobs](0016-tombstones-immutable-blobs-and-merge-redirects.md) | Deletion and merge preserve identity; blob references point to immutable payloads. | Accepted. |
| [0017 Metadata lookup boundary](0017-book-metadata-lookup-provider-boundary.md) | Lookup providers return storage-neutral candidates; the app decides what to persist. | Accepted. |
| [0018 Application-owned configuration](0018-application-owned-service-configuration.md) | The app owns user configuration and injects it into reusable packages. | Accepted; [0020](0020-service-owned-application-preferences.md) clarifies app-service preference ownership. |
| [0019 Documentation history](0019-documentation-history-and-maintenance.md) | Preserve journals as history, keep core docs current, and supersede changed decisions explicitly. | Accepted. |
| [0020 Service-owned preferences](0020-service-owned-application-preferences.md) | Each durable app preference has one owning service and an injected settings store. | Accepted; refines [0018](0018-application-owned-service-configuration.md). |
| [0021 Index-configured creation](0021-index-configured-record-creation.md) | Index metadata defines New actions; creation currently selects a matching index and record. | Accepted. |
| [0022 Service state, API, and access](0022-service-state-api-and-provider-shape.md) | Services separate view-facing `State` from command-facing `API` and nested `Access`. | Accepted; refines [0001](0001-engine-command-boundary.md) and partly supersedes [0014](0014-narrow-command-providers-and-services.md). |
| [0023 Mutation creation time](0023-mutation-creation-time-ordering.md) | Mutations carry a precise, strictly increasing creation time; with the identifier it totally orders any mutation set. | Accepted; refines [0002](0002-mutation-log-and-record-projection.md) and [0010](0010-application-neutral-datastore.md). |
| [0024 Import audit records](0024-import-sessions-produce-audit-records.md) | Every import session that changes the catalogue writes an `import` record of what it changed, viewable in an Imports index. | Accepted. |
