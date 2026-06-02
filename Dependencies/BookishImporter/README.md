# BookishImporter

`BookishImporter` contains importers that translate external book-library data
into Bookish's storage-neutral import model.

The package currently supports:

- registering importer implementations with `ImportManager`;
- creating asynchronous `ImportSession` instances for recognised sources;
- importing Delicious Library XML property-list exports; and
- forwarding imported books to clients as `BookRecord` values through
  `ImportDelegate`.

The importer package depends on `BookishCore` for the shared `BookRecord` type
and the related JSON interchange types. It does not write to the application
datastore directly, and it does not currently emit `.bookish` interchange files
itself. Clients decide whether imported records should create new catalogue
records, update existing records, or be exported in another form.

## Import Flow

An `Importer` declares the source types it recognises and creates an
`ImportSession` when it can handle a supplied source. `ImportManager` tries the
registered importers in identifier order and starts the first session that
accepts the source.

Sessions report progress through `ImportDelegate`:

- `session(_:willImportItems:)` announces the expected number of source items;
- `session(_:didImport:)` delivers each imported `BookRecord`;
- `sessionDidFinish(_:)` marks a completed import; and
- `sessionDidFail(_:)` reports a failed session.

`BookRecord` is a dictionary-backed value with three core fields:

- `id`: a stable source-specific identifier for the imported book;
- `title`: the imported book title; and
- `source`: the importer or service identifier that produced the record.

All additional metadata is stored in `properties`. Shared book metadata keys are
defined by `BookKey`, including `isbn`, `authors`, `publishers`, `series`,
`seriesPosition`, `publishedDate`, `imageURLs`, `importedID`, and
`importedDate`.

## Interchange Format

The JSON interchange container is defined in `BookishCore`, not in this package.
It is the related storage-neutral export model used by application clients when
exchanging materialised catalogue data.

An encoded interchange file has this top-level shape:

```json
{
  "type": {
    "format": "com.elegantchaos.bookish.list",
    "version": 1,
    "variant": "compact"
  },
  "creator": {
    "id": "com.elegantchaos.bookish",
    "version": "1.0",
    "build": 1,
    "commit": "sha-hash"
  },
  "root": "root-record-id",
  "content": [
    {
      "id": "record-id",
      "name": "Display Name",
      "kind": "book",
      "checksum": 123456,
      "items": [],
      "links": [],
      "title": "Display Name",
      "isbn": "9780000000000"
    }
  ]
}
```

### Header

`type` identifies the interchange family:

- `format`: a reverse-DNS style format identifier;
- `version`: the format version; and
- `variant`: an optional variant. The defined variants are `normal` and
  `compact`; omitted means `normal`.

`creator` identifies the application build that produced the file:

- `id`: bundle or application identifier;
- `version`: human-readable version;
- `build`: build number; and
- `commit`: source revision string.

`root` is optional. When present, it names the root record for the exported
selection.

### Content

`content` is an array of records. Each record has an identity block and a flat
property dictionary.

Required identity fields:

- `id`: stable record identifier;
- `name`: display name;
- `kind`: application-level record kind such as `book`, `list`, `person`,
  `organisation`, `series`, `role`, or `link`;
- `checksum`: a producer-calculated checksum for change detection;
- `items`: ordered child or list-entry record references; and
- `links`: reverse or related record references.

`items` and `links` contain `InterchangeID` dictionaries with the same `id`,
`name`, `kind`, and `checksum` fields. They are references, not embedded record
definitions. Referenced records should also appear in `content` when the export
needs to be self-contained.

Any other keys on the record are catalogue properties. Values must be JSON-safe
primitive or collection values, such as strings, numbers, booleans, arrays, and
dictionaries. Date and URL values are expected to be represented in a
JSON-compatible form before encoding.

### Current Implementation Notes

The current writer flattens record properties beside the identity fields, as
shown above. The current `InterchangeRecord` decoder does not yet mirror that
encoded shape: it expects a nested `properties` dictionary, does not decode the
flat identity fields into an `InterchangeID`, and expects already-materialised
`InterchangeID` values in `items` and `links`. Import support for `.bookish`
interchange files is therefore not complete yet.

The application also has a `BookishInterchangeImporter` placeholder, but its
session currently emits an empty record list. Treat the JSON format as the
exported interchange shape, not as a completed round-trip import path.

## Compatibility With The Current Catalogue Model

The interchange format is compatible with the broad direction of the current
catalogue model because it represents stable, schema-less records with a `kind`
string and flexible properties. This matches the application-level idea that
books, people, organisations, series, lists, roles, and relationship records are
conventions over generic records.

It is only partially compatible with the latest datastore design:

- Record identity maps cleanly from `InterchangeID.id` to `RecordID.rawValue`.
- `kind` maps cleanly to `StoredRecord.kind`.
- Flat JSON properties can be converted to `RecordPropertyValue` for primitive
  strings, integers, doubles, booleans, and lists.
- `items` and `links` can be represented as record-link properties or list
  properties in the datastore, but their semantics are not explicit enough to
  distinguish child containment, list membership, backlinks, or rich
  relationship records without importer-specific conventions.
- `checksum` is useful as export metadata, but it is not part of the datastore
  mutation model and should not be treated as authoritative state.
- The format does not represent typed property values, blob references,
  tombstones, deletion markers, conflict markers, mutation identifiers, parent
  mutation links, list-entry identities, ordering metadata, or mutation history.

For user-facing import/export, this format is a reasonable materialised-record
snapshot format. For the newer datastore, a production importer should translate
each interchange record into explicit datastore mutations or a documented
snapshot import path. A future version of the interchange format should also
define reserved property names for record type, deletion state, blob references,
record links, relationship records, and ordered list entries so imports can be
lossless against the catalogue model.
