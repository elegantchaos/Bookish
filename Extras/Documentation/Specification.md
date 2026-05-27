# Bookish Specification

## Purpose

Bookish is a personal book cataloguing app for maintaining a durable, searchable record of books, people, publishers, series, lists, and reading-related metadata.

The new iteration should preserve the project’s flexible record model while modernising the app around Swift 6, SwiftUI, SwiftData, and a cleaner separation between domain logic, persistence, import/export, and user interface code.

## Product Goals

- Make it fast to add books by search, ISBN/barcode scan, import, or manual entry.
- Let users organise books into lists, series, roles, and custom relationships without forcing a rigid schema.
- Support rich metadata for books, people, organisations, series, and user-defined fields.
- Keep the catalogue portable through explicit import/export formats.
- Provide a native SwiftUI experience that works well across Apple platforms, with iOS and macOS as the primary targets.
- Keep the data model robust enough for future sync without coupling core logic to a particular sync provider.

## Core Concepts

- **Record**: the base unit of catalogue data. Records have stable identifiers, names, kinds, optional images, and flexible properties.
- **Book**: the central record type, with standard metadata such as title, identifiers, authors, publisher, publication details, cover artwork, and user fields.
- **Person**: an author, illustrator, editor, narrator, contributor, or other individual connected to books.
- **Organisation**: a publisher, imprint, retailer, library, or other institution.
- **Series**: an ordered or semi-ordered group of books.
- **List**: a user-managed collection such as wishlist, owned, loaned, favourites, imports, or reading history.
- **Role**: the semantic meaning of a relationship, such as author, illustrator, publisher, owner, read, or wishlist item.
- **Link**: a first-class relationship between records, optionally carrying a role, order, dates, notes, or other properties.

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

Initial import/export support should prioritise existing Bookish interchange files and legacy Delicious Library-style data, then leave space for additional formats.

## Data Model Direction

The modern app should move from the legacy Core Data-backed `CDRecord`/`CDProperty` implementation to SwiftData models that retain the same conceptual shape:

- stable IDs;
- typed record kinds;
- flexible properties;
- first-class links;
- list order and relationship metadata;
- import/export through simple interchange records.

The low-level interchange model should remain storage-independent. Importers, lookup services, cleanup tools, and tests should depend on the interchange/domain layer rather than SwiftData.

## Architecture

Bookish should be organised into focused modules:

- **Core**: storage-independent domain types, record keys, interchange records, validation, cleanup, and pure transformations.
- **Persistence**: SwiftData models, migrations, fetch/query helpers, and persistence-specific mapping.
- **Importer**: import sessions, format-specific importers, and conversion into interchange records.
- **Lookup**: external lookup services and candidate matching.
- **App/UI**: SwiftUI views, navigation, editing flows, scanning, preferences, and platform integration.

Domain logic should be testable without launching the app or touching persistent stores. UI code should consume small view models or query wrappers rather than embedding persistence details deeply in views.

## Non-Goals for the First Modernisation Pass

- Do not attempt to support every historic legacy feature before the new model is stable.
- Do not tie sync design to a specific provider until the local data model and migrations are proven.
- Do not require users to understand the low-level graph/link model for common workflows.
- Do not make importers responsible for app-specific persistence decisions.

## Quality Bar

- Core transformations and import/export behavior must have focused tests.
- SwiftUI views should have previews for representative empty, populated, and error states.
- Migration work must include repeatable fixtures for legacy data.
- The app should make destructive catalogue operations explicit and reversible where practical.
- Documentation should stay aligned with the implemented model, especially `Database.md` and this specification.

## Open Questions

- Which Apple platforms are primary for the next release: iOS, macOS, or both equally?
- Should SwiftData sync target CloudKit, local-only storage first, or a provider-neutral abstraction?
- Which legacy import formats are required for the first usable version?
- What metadata fields are first-class versus custom properties?
- How much of the current flexible graph model should be exposed directly in the UI?
