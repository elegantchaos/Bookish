# Interchange Design

Bookish interchange files provide a JSON-based format for moving catalogue data
between import tools, lookup tools, scanning tools, application clients, and
storage implementations.

The interchange format is future-facing and storage-neutral. It is based on the
record model described in `Catalogue Model.md` and should remain compatible with
the materialised record and mutation model described in `Datastore Design.md`.

## Goals

- Use one canonical record representation for import, export, lookup, scanning,
  commands, and datastore snapshots.
- Keep import, lookup, scanning, and persistence providers black-box to clients.
- Preserve enough structure to import catalogue data without stringly-typed
  special cases in the application model.
- Keep JSON files readable and practical to edit by hand.
- Support compact encoding for common primitive values.
- Support explicit encoding for links, blobs, tombstones, deletions, conflicts,
  and other values that are ambiguous in plain JSON.
- Allow compatible external JSON by making reserved record keys configurable.

## Core Model

The interchange format is built around records and values.

A **record snapshot** is a materialised record at a point in time. It has:

- a stable identifier;
- a `kind`, such as `book`, `person`, `organisation`, `series`, `list`, `role`,
  `relationship`, or `layout`;
- a dictionary of named properties.

A **record value** is any value that can appear in a record property. Record
values include primitives, encoded payloads, record links, blob references,
lists, tombstones, deletion markers, and conflict markers.

The JSON representation may be compact, but the decoded application model should
always use explicit `RecordSnapshot` and `RecordValue` values. JSON shorthand
must not leak into the datastore, commands, import results, or user interface
model.

## File Shape

An interchange file contains format metadata, optional schema customisation, an
optional root record, and a list of records.

```json
{
  "format": {
    "id": "com.elegantchaos.bookish.records",
    "version": 1
  },
  "schema": {
    "idKey": "id",
    "kindKey": "kind",
    "defaultKind": "record",
    "rvKey": "®"
  },
  "root": "@book-1",
  "records": [
    {
      "id": "book-1",
      "kind": "book",
      "title": "Snow Crash",
      "isbn": "9780553380958",
      "authors": ["@person-neal-stephenson"],
      "publisher": { "®": "record", "id": "org-bantam" }
    },
    {
      "id": "person-neal-stephenson",
      "kind": "person",
      "name": "Neal Stephenson"
    }
  ]
}
```

`format` identifies the interchange family and version.

`schema` is optional. Missing schema fields use the default values described in
the next section.

`root` is optional. When present, it identifies the record that should be treated
as the root of the imported or exported selection. It may use the same record
link shorthand as property values.

`records` contains record snapshots. Each record is decoded using the active
schema.

## Schema

The schema defines reserved JSON keys and default record behaviour.

Default schema:

```json
{
  "idKey": "id",
  "kindKey": "kind",
  "defaultKind": "record",
  "rvKey": "®"
}
```

`idKey` is the record field that stores the record identifier.

`kindKey` is the record field that stores the application-level record kind.
The format uses `kind`, not `type`, to make it clear that this value is part of
the catalogue model rather than a language-level type.

`defaultKind` is used when a record omits the `kindKey` field.

`rvKey` is the reserved object key that marks an object as an explicitly typed
`RecordValue`.

## Record Decoding

When decoding a record:

1. Read the record identifier from `idKey`.
2. Read the record kind from `kindKey`.
3. If the record omits `kindKey`, use `defaultKind`.
4. Decode every remaining key as a record property.

Reserved record keys are not included in the property dictionary unless an
importer deliberately remaps them through a non-default schema.

Record identifiers must be stable strings. The default accepted lexical form is:

```text
^[A-Za-z0-9][A-Za-z0-9._:-]*$
```

This keeps identifiers readable, URL-friendly, and unambiguous when used with
compact record link shorthand.

## Record Values

Primitive JSON values decode directly where their meaning is unambiguous:

```json
{
  "title": "Snow Crash",
  "pages": 470,
  "rating": 4.5,
  "owned": true,
  "tags": ["fiction", "cyberpunk"]
}
```

These values decode as strings, integers, doubles, booleans, and lists.

Plain JSON objects without `rvKey` are not valid property values. A structured
payload encoded from a small Codable value must use the explicit `encoded`
record value form:

```json
{
  "dimensions": {
    "®": "encoded",
    "width": 5.5,
    "height": 8.25,
    "unit": "in"
  }
}
```

For `encoded` values, every key other than the schema's `rvKey` is part of the
opaque JSON payload. The interchange file does not provide a Swift type name;
application code is expected to know the Codable type it wants to decode for a
given property.

Objects that contain `rvKey` decode as explicitly typed record values. The
following reserved value kinds are defined:

- `record`: a link to another record;
- `blob`: a reference to out-of-line blob data;
- `date`: a date encoded as a string value;
- `encoded`: an opaque JSON payload encoded from a small Codable value;
- `tombstone`: a tombstoned record marker;
- `deletion`: a deleted property marker;
- `conflict`: a conflict marker containing alternative values.

## Explicit Record Value Objects

Record links use the canonical explicit form:

```json
{
  "®": "record",
  "id": "person-neal-stephenson"
}
```

Blob references identify immutable out-of-line data:

```json
{
  "®": "blob",
  "id": "cover-snow-crash",
  "mediaType": "image/jpeg",
  "byteCount": 123456,
  "checksum": "sha256:..."
}
```

Dates are encoded explicitly when the value must remain a date rather than a
plain string:

```json
{
  "®": "date",
  "value": "2026-06-02T10:00:00Z"
}
```

Tombstones and deletion markers are explicit sentinel values:

```json
{
  "®": "tombstone"
}
```

```json
{
  "®": "deletion"
}
```

Conflict values preserve alternatives until the application can resolve them:

```json
{
  "®": "conflict",
  "values": ["Original Title", "Edited Title"]
}
```

The `rvKey` field name is schema-controlled, so the same values can be encoded
with another reserved key when importing or exporting a compatible external JSON
shape.

## Record Link Shorthand

The canonical record link form is the explicit `record` value object. The JSON
codec may also support a compact shorthand for human-authored files:

```json
"@person-neal-stephenson"
```

The shorthand is JSON syntax only. It always decodes to the same internal value
as the explicit object form:

```json
{
  "®": "record",
  "id": "person-neal-stephenson"
}
```

To qualify as shorthand, a string must:

- start with `@`;
- contain no whitespace;
- have at least one character after `@`;
- have a suffix that matches the record identifier pattern.

Default shorthand pattern:

```text
^@[A-Za-z0-9][A-Za-z0-9._:-]*$
```

Strings that do not match the shorthand pattern decode as ordinary strings.

```json
{
  "author": "@person-neal-stephenson",
  "title": "@ Home",
  "note": "email me @ example"
}
```

Only `author` is a record link. `title` and `note` are plain strings.

Writers should use the explicit record object form by default. Shorthand output
may be enabled for compact or human-authored interchange variants.

## Lists And Relationships

Lists are represented as record value lists. Simple lists can contain direct
record links:

```json
{
  "kind": "list",
  "id": "list-favourites",
  "name": "Favourites",
  "items": ["@book-1", "@book-2"]
}
```

Common catalogue connections use direct record links. For example, a book's
ordered `authors` list directly identifies its authors, and its `series` property
directly identifies its series. The list order establishes contributor sequence.

Connections that need metadata can use a relationship record. For example, a
contributor relationship can preserve the contributor's role, credited-as name,
and source-specific notes:

```json
{
  "id": "relationship-book-1-contributor-1",
  "kind": "relationship",
  "from": "@book-1",
  "to": "@person-anthea-bell",
  "role": "translator",
  "creditedAs": "Anthea Bell",
  "sourceNote": "Title-page credit"
}
```

This keeps simple links compact while preserving a representation for catalogue
connections with their own metadata.

## Encoding Rules

Encoders should:

- emit `format`;
- emit `schema` only when non-default values are used, or when clarity is more
  important than compactness;
- emit record `idKey` and `kindKey` fields for every record unless an explicit
  compact mode omits `kindKey` for records using `defaultKind`;
- encode primitive record values as primitive JSON values;
- encode ambiguous values as explicit `RecordValue` objects;
- use explicit record link objects by default;
- use shorthand record links only when an output option requests them.

Decoders should:

- apply default schema values when `schema` or schema fields are missing;
- treat unknown explicit `rvKey` values as errors in strict mode;
- preserve unknown explicit `rvKey` values only through a future explicit
  extension point when the caller requests that behaviour;
- reject plain JSON object property values that do not contain `rvKey`;
- reject malformed record identifiers in strict mode;
- treat non-matching shorthand-like strings as plain strings.

## Import And Export Semantics

User-facing import and export should operate on materialised record snapshots.
The interchange format is not the sync protocol and is not required to include
mutation history.

When importing into the datastore, an importer should translate decoded records
into application-level commands or datastore mutations. Whole-record upsert is
acceptable for bootstrapping, backup restore, and explicit snapshot import.
Normal user edits should still use property-level and list-entry mutations so
sync and conflict handling remain precise.

Diagnostic, archive, or recovery formats may include mutation history in a
separate future format. That should not complicate the materialised record
interchange format used by import, lookup, scanning, and ordinary export.

## Open Questions

- Should shorthand record links be allowed by default during decoding, or only
  when the file schema explicitly enables them?
- Should the record identifier pattern be schema-configurable, or fixed for all
  Bookish interchange files?
- What exact metadata is required for blob references before production import
  and export?
- How should compact output represent omitted `kind` values when a file contains
  mixed record kinds?
