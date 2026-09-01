# Bookish Specification

## Purpose

Bookish is a personal book cataloguing app for maintaining a durable, searchable record of books, people, publishers, series, lists, and reading-related metadata.

Bookish preserves a flexible record model while keeping clear boundaries between domain logic, storage, import/export, and user interface code.

## Product Goals

- Make it fast to add books by search, ISBN/barcode scan, import, or manual entry.
- Let users organise books into lists, series, roles, and custom relationships without forcing a rigid schema.
- Support rich metadata for books, people, organisations, series, and user-defined fields.
- Keep the catalogue portable through explicit import/export formats.
- Provide a native Apple-platform experience, with iOS and macOS as the primary targets.
- Keep the data model robust enough for future sync without coupling core logic to a particular sync provider.

## Core Concepts

- **Record**: the base unit of catalogue data. Records have stable identifiers, names, kinds, optional images, and flexible properties.
- **Book**: the central record type, with standard metadata such as title, identifiers, authors, publisher, publication details, cover artwork, and user fields.
- **Person**: an author, illustrator, editor, narrator, contributor, or other individual connected to books.
- **Organisation**: a publisher, imprint, retailer, library, or other institution.
- **Series**: an ordered or semi-ordered group of books.
- **List**: a user-managed collection such as wishlist, owned, loaned, favourites, imports, or reading history.
- **Role**: the semantic meaning of a relationship, such as author, illustrator, publisher, owner, read, or wishlist item.
- **Link**: a first-class relationship between records, optionally carrying a role, dates, notes, or other properties.

## Main Workflows

### Add Books

Users can add one or more books by:

- searching external lookup services;
- scanning an ISBN/barcode;
- importing supported file formats;
- duplicating or editing an existing record;
- entering details manually.

The app should show candidate matches before insertion, allow users to choose the best result, and avoid creating obvious duplicates.

### Browse and Search

Users can browse by book, person, organisation, series, list, role, and custom index. Search should cover titles, names, identifiers, and important metadata. Navigation should make relationships visible in both directions, such as from a book to its authors and from an author to their books.

### Edit Metadata

Users can edit standard fields and custom fields. The app should preserve unknown imported fields where possible, expose raw properties for advanced cleanup, and keep common editing actions efficient.

### Organise Records

Users can create and maintain:

- ordered lists;
- unordered collections;
- series order;
- reading history entries;
- arbitrary relationships with roles;
- custom indexes and fields.

The model should allow the same book to appear in multiple lists or multiple times in a list when the use case requires it.

### Import and Export

Importers should transform external data into the interchange record format before touching app storage. Export should use the same interchange model so catalogue data remains portable and testable outside the UI.

Import/export support should prioritise Bookish interchange files and Delicious Library-style data, while leaving space for additional formats.

## Data Persistence Model

The app data model is based around untyped records, which support a key/value abstraction.

Key properties of the abstraction:
- Records have stable ids.
- Record properties are accessed using dot-separated string keys. 
- Values can be primitive types, codable types, or references to other records.
- Nested properties are supported.
- The implementation of nested values is hidden:
  - could be resolved via references to subrecords
  - could be directly stored using fully qualified keys
  - could be an encoded contained in a top-level value
- Relationships between records can use direct record references, ordered lists of record references, or relationship records when metadata is needed.
- Relationship records can carry key/value metadata such as a contributor role, credited-as name, or source-specific notes.
- Relationships can be one-to-one or one-to-many.
  
### Persistence

Persistence and synchronisation is assumed to be transparently handled by the data provider. The app is notified when data is changed externally. The app requests changes to data explicitly.

Records are never deleted, only marked as deleted, and can therefore be restored.

### Interchange

The database can essentially be viewed as a graph of key/value records.

An individual record, a collection of records, or the entire database should be representable as JSON. 

The interchange model should remain storage-independent. 

Importers, lookup services, cleanup tools, and tests should depend either on the persistence abstraction, or on the JSON interchange format.

## Data Views And Types

Although data records are untyped value/value stores, they are treated as typed by convention within the application, so that it can collect them into indexes (books, authors, and so on), and manage the connections between them.

Types are indicated by the value of one or more predefined key/value pairs on a record (eg a `_type` property).

The application should support a flexible display and editing user interface, based on description records.

A description is a record which indicates how to display other records:
- which properties to display
- the order to display them in
- the expected data type of each property
- the ui component to use to display each property
- whether properties are optional
- whether to show placeholders or empty ui components for missing properties
- how to manage links to other records

Because types are not strict, it is possible for an individual record to be view as more than one type, or for its type to be changed at runtime. This isn't necessarily a facility that the application requires, but it should be possible.  

## Architecture

Bookish should be organised into focused modules:

- **Core**: storage-independent domain types, record keys, interchange records, validation, cleanup, and pure transformations.
- **Persistence**: storage models, migrations, fetch/query helpers, and persistence-specific mapping.
- **Importer**: import sessions, format-specific importers, and conversion into interchange records.
- **Lookup**: external lookup services and candidate matching.
- **App/UI**: views, navigation, editing flows, scanning, preferences, and platform integration.

Domain logic should be testable without launching the app or touching persistent stores. UI code should consume small view models or query wrappers rather than embedding persistence details deeply in views.

Bookish should adopt the project layout described in `Project Layout.md`: a thin root app target over reusable Swift packages under `Dependencies/`, with documentation, scripts, reference material, and planning notes kept under `Extras/`.

## Non-Goals

- Do not attempt to support every specialised catalogue feature before the core model is stable.
- Do not tie sync design to a specific provider until the local data model and migrations are proven.
- Do not require users to understand the low-level graph/link model for common workflows.
- Do not make importers responsible for app-specific persistence decisions.

## Quality Bar

- Core transformations and import/export behavior must have focused tests.
- Views should have previews for representative empty, populated, and error states.
- Migration work must include repeatable fixtures for imported catalogue data.
- The app should make destructive catalogue operations explicit and reversible where practical.
- Documentation should stay aligned with the implemented model, especially `Catalogue Model.md`, `Datastore Design.md`, `Data View Design.md`, and this specification.

## Open Questions

- Which Apple platforms are primary for the next release: iOS, macOS, or both equally?
- Should sync target CloudKit, local-only storage, or a provider-neutral abstraction?
- Which import formats are required for the first usable version?
- What metadata fields are first-class versus custom properties?
- How much of the flexible graph model should be exposed directly in the UI?
