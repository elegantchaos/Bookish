# Data View Design

Bookish stores flexible, schema-less records. The user interface is configured by records in the same datastore rather than by a fixed application schema. This allows the application to provide useful seeded defaults while letting users add record types, fields, layouts, indexes, labels, and specialised viewers without changing persistence code.

The datastore remains deliberately permissive. Metadata affects how a value is discovered, displayed, and edited; it does not make a value invalid or prevent a record from having an otherwise unknown property.

## Dynamic User Interface

The UI reads materialised records through the record service and writes through the mutation service. It also reads metadata records through the same services. A presentation resolver combines a data record, its type metadata, and an optional layout into a display-ready description before SwiftUI renders it.

Views must not query the record store while constructing `body`. The application or a presentation service resolves and observes the relevant metadata, then supplies stable presentation values to the views.

The resolver uses this order of precedence:

1. Generic metadata for every record type.
2. Metadata for the data record's type.
3. Metadata supplied by the active layout.

Metadata is merged property by property. Within a property description, each supplied member overrides the corresponding lower-precedence member. For example, a layout can change the label for `authors` while retaining the generic icon and type-specific viewer.

When no metadata applies, the UI presents a property with a generated label and a generic value viewer. An absent or unknown viewer identifier must always fall back safely rather than making a record unusable.

## Property Presentation Metadata

Property presentation metadata is planned as a small encoded map stored in metadata and layout records. Each entry is keyed by the datastore property identifier and has this conceptual shape:

```swift
struct PropertyPresentation: Codable, Equatable, Sendable {
  var icon: String?
  var label: String?
  var viewer: String?
}
```

- `icon` is an SF Symbol name.
- `label` is a user-facing string. Seeded values use domain-style dotted localisation keys, such as `property.book.authors`. The UI attempts localisation and displays the string itself when no translation exists, which also supports user-entered labels.
- `viewer` selects the SwiftUI presentation and editing component. It is an advisory, stable identifier such as `text`, `date`, `record.link`, `record.linkList`, `image.url`, or `identifier.isbn`.

The record value remains authoritative. A viewer does not validate or constrain the `BookishRecordValue` stored for a property. It chooses the most suitable interface when the value is compatible and otherwise uses a generic value viewer or repair path.

## Metadata Records

Metadata records describe a record type rather than a particular data record. The planned metadata record identity is derived from the target type:

- `metadata.type.*` supplies the generic fallback.
- `metadata.type.book` supplies book-specific presentation metadata.
- `metadata.type.person` supplies person-specific presentation metadata.

The `*` record is the universal fallback. `record` must not be used as that fallback because it is itself a valid record type.

The precise stored key for the encoded property-presentation map is an implementation detail, but it belongs on these metadata records. Layout records contain the same kind of map for their local overrides. This keeps related property descriptions together, avoids a large number of auxiliary records and lookups, and permits future descriptor fields without adding association-property naming conventions.

## Layout Records

Records of kind `layout` determine which properties are shown and in what order. Their `fields` property is an ordered list of property identifiers. The `*` token expands to every property not already listed, in stable key order.

Layouts also have an advisory `types` list describing the record types they are designed to present. A `*` entry matches every type. Missing or empty type lists are treated permissively so old and custom layouts remain usable.

The browser uses the selected index's types to offer compatible layouts. A layout-specific presentation override is only relevant when the layout matches the record being shown.

Seeded layouts include an all-fields layout for `*` and type-specific layouts for standard catalogue and metadata record types. Users will be able to duplicate, edit, and create layouts without changing the stored records they present.

## Index User Interface

The first column of the browser is driven by records of kind `index`. An index record stores:

- `name`: the name displayed in the index list;
- `position`: its stable display order;
- `debugOnly`: whether it is normally hidden from non-debug browsing;
- `query`: an encoded `RecordQuery` containing a predicate and ordered sort descriptors;
- `types`: an advisory list of record types the query can surface;
- `layout`: an optional preferred layout record link.

The selected index's query is executed by the datastore query service. Its observable, ordered result drives the content column; selecting a record from that result drives the detail column. This means indexes are normal, inspectable, syncable records, and the browser does not need hard-coded tabs for books, people, lists, or future categories.

The application seeds standard indexes for books, people, organisations, series, lists, and relationships. `All Records`, `Layouts`, and `Indexes` are debug-only indexes. The default browser hides `debugOnly == true` entries, while debug browsing can include them.

An index type list does not validate its query or the records returned by it. It guides choices such as the layouts offered for that index. `*` describes an index that may return mixed record types.

## Planned Index Authoring

Index records are designed to be user-authored. The index editor will allow users to:

- create, duplicate, rename, reorder, and remove indexes;
- choose the record types an index is expected to surface, including `*` for mixed results;
- build and edit query predicates, including record type and relationship conditions;
- add, remove, and reorder sort descriptors with ascending or descending direction;
- select a compatible default layout;
- preview the resulting records before saving;
- choose whether an index is ordinary, debug-only, or eventually private to a particular workflow.

The editor should expose only the query operations the record service can execute. It should preserve an index's stored query when a newer UI does not understand part of it, and report invalid query data clearly rather than silently broadening the result set.

## Editing Flow

Views do not write directly to the record store. Editing a data record, layout, index, or metadata record produces normal application-level mutations. The mutation service applies the mutation, the record service updates its materialised projection, and observed query and presentation state refreshes the interface.

User customisation should not require knowledge of mutations, encoded payloads, or the datastore's internal representation.

## Implementation Status

Implemented now:

- flexible `BookishRecord` properties and storage-neutral values;
- stored `layout` and `index` records seeded from interchange data;
- layout field ordering and `*` expansion;
- encoded index queries, observable query results, and stable sorting;
- advisory index and layout `types` lists, including `*` matching;
- compatible-layout filtering in the browser.

Planned next:

- metadata records for generic and type-specific property presentation;
- layout-level property-presentation overrides;
- a resolver that creates effective `PropertyPresentation` values;
- viewer registration and generic fallback viewers;
- index, layout, and metadata editing interfaces.
