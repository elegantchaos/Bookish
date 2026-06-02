# Bookish Importer Interchange Review

Reviewed `Dependencies/BookishImporter` and the shared `BookishCore`
interchange model against the current catalogue and datastore design.

Findings:

- `BookishImporter` imports external library sources into `BookRecord` values
  and delivers them through `ImportDelegate`; it does not write directly to the
  datastore.
- Delicious Library XML import is the main concrete importer in the package.
- The JSON interchange model lives in `Dependencies/BookishCore` and currently
  exports materialised records with identity fields, flat JSON properties, and
  simple `items`/`links` references.
- The interchange shape is broadly aligned with the schema-less catalogue model,
  but only partially aligned with the datastore prototype.

Compatibility notes:

- `InterchangeID.id` can map to `RecordID.rawValue`.
- `kind` can map to `StoredRecord.kind`.
- Primitive JSON properties can map to `RecordPropertyValue` cases.
- `items` and `links` need clearer semantics before they can be imported
  losslessly as datastore links, ordered lists, or relationship records.
- The format does not yet encode typed property values, blob references,
  tombstones, deletion markers, conflict values, list-entry identities, mutation
  parents, or mutation history.
- `InterchangeRecord` decoding and the app-level `BookishInterchangeImporter`
  are not complete enough for a full export/import round trip.

Updated `Dependencies/BookishImporter/README.md` with a package summary,
import flow documentation, interchange JSON documentation, and compatibility
review.

Interchange design update:

- Added `Extras/Documentation/Interchange Design.md` as the future-facing design
  for Bookish JSON interchange.
- Standardised schema terminology around `idKey`, `kindKey`, `defaultKind`, and
  `rvKey`.
- Documented record snapshots as the materialised interchange record model, with
  all non-reserved record keys decoded as properties.
- Documented compact `RecordValue` decoding, explicit typed value objects, and
  optional JSON-only record link shorthand such as `@person-neal-stephenson`.
- Kept the canonical record link representation as
  `{ "_rvtype": "record", "id": "record-id" }`, with shorthand treated only as a
  codec-level convenience.
