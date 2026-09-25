# Bookish Specification

## Purpose

Bookish is a personal book cataloguing app for maintaining a durable, searchable record of books, people, publishers, series, lists, and reading-related metadata.

Bookish preserves a flexible record model while keeping clear boundaries between
domain logic, import/export, user interface code, and its application-neutral
Datastore dependency.

## Product Goals

- Make it fast to add books by search, ISBN/barcode scan, import, or manual entry.
- Let users organise books into lists, series, roles, and custom relationships without forcing a rigid schema.
- Support rich metadata for books, people, organisations, series, and user-defined fields.
- Let users customise both data and visual layouts through free-form record
  properties, user-authored layouts, lists, and queries.
- Keep the catalogue portable through explicit import/export formats.
- Import and preserve data from competing catalogue and ebook-library
  applications, including Kindle and Apple Books where their data can be
  accessed through supported import mechanisms.
- Discover and add books from camera images, live scenes, and video using AI
  recognition as well as barcode scanning.
- Discover and enrich book metadata from multiple sources, including Amazon,
  Open Library, and other free or commercial providers.
- Provide a native Apple-platform experience on macOS and iOS, including iPhone
  and iPad.
- Keep the catalogue durable and ready for synchronisation without coupling
  Bookish workflows to a storage implementation.

## Platform Baseline

Bookish currently supports macOS 26.0 and iOS 26.0 or later. Before the first
release, the minimum deployment target is expected to move to macOS 27.0 and
iOS 27.0 so Cloud Foundation Models APIs are part of the platform baseline.

Foundation Models features must still handle runtime unavailability caused by
device eligibility, account state, system settings, or model readiness.

## Core Concepts

- **Record**: the base unit of catalogue data. Records have stable identifiers, names, kinds, optional images, and flexible properties.
- **Book**: the central record type, with standard metadata such as a name, identifiers, authors, publisher, publication details, cover artwork, and user fields.
- **Person**: an author, illustrator, editor, narrator, contributor, or other individual connected to books.
- **Organisation**: a publisher, imprint, retailer, library, or other institution.
- **Series**: an ordered or semi-ordered group of books.
- **List**: a user-managed collection such as wishlist, owned, loaned, favourites, imports, or reading history.
- **Role**: the semantic meaning of a relationship, such as author, illustrator, publisher, owner, read, or wishlist item.
- **Link**: a first-class relationship between records, optionally carrying a role, dates, notes, or other properties.

## Application Data Model

At its lowest level, Bookish uses a directed graph of records supplied by
Datastore. Records have stable identities, named properties, and directed links
to other records or ordered lists of links.

Datastore does not assign catalogue meaning to that graph. Bookish overlays its
own high-level interpretation to determine how records are used, related,
interpreted, and displayed. Record kinds, properties, links, layouts, indexes,
and presentation metadata are all part of that application-level interpretation.

## Main Workflows

### Add Books

Users can add one or more books by:

- searching external lookup services;
- scanning an ISBN/barcode;
- recognising books from camera images, scenes, or video;
- importing supported file formats;
- duplicating or editing an existing record;
- entering details manually.

The app should show candidate matches before insertion, allow users to choose the best result, and avoid creating obvious duplicates.

### Browse and Search

Users can browse by book, person, organisation, series, list, role, and custom index. Search should cover names, identifiers, and important metadata. Navigation should make relationships visible in both directions, such as from a book to its authors and from an author to their books.

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

### Customise Data and Visual Layout

Users can add record properties free-form, without requiring a predefined field
for every value. They can also define layouts that choose record properties,
their order, labels, viewers, and other presentation details.

Users can define lists of books or other record kinds and select the layout used
to display them. A query may apply to a list's contents or to all records and
produce a derived list or sub-list for display with a chosen layout. Derived
results do not duplicate their source records.

### Import and Export

Importers should transform external data into the interchange record format before touching app storage. Export should use the same interchange model so catalogue data remains portable and testable outside the UI.

Import/export support should prioritise Bookish interchange files and Delicious
Library-style data, while supporting migration from additional catalogue and
ebook-library applications where their data can be accessed through supported
mechanisms. Metadata lookup and enrichment should use multiple providers rather
than depending on one vendor.

## Datastore Dependency

Bookish builds on Datastore as an application-neutral dependency. Datastore owns
the storage and synchronisation mechanics that Bookish does not specify. Bookish
supplies catalogue conventions, user workflows, import interpretation,
presentation, and commands.

Bookish accesses and changes catalogue data through Datastore's public interface.
It does not depend directly on a storage engine or synchronisation transport.

The detailed contracts are documented in [Datastore Design](Datastore%20Design.md)
and [Datastore Implementation](Datastore%20Implementation.md). The application
record model is documented in [Catalogue Model](Catalogue%20Model.md).

### Interchange

Bookish uses storage-neutral JSON record documents for import, export, tooling,
and fixtures. Importers transform external data into the interchange model before
requesting durable persistence. The file-format contract is documented in
[Interchange Design](Interchange%20Design.md).

## Kinds and Presentation

Although data records are untyped value/value stores, they are treated as typed by convention within the application, so that it can collect them into indexes (books, authors, and so on), and manage the connections between them.

Kinds are indicated by the record's `kind` value. A kind is an application-level
catalogue convention, not a language-level type or a fixed persistence schema.

The application should support a flexible display and editing user interface, based on configuration records. See `Browser and Presentation Design.md`.

Layout and presentation records indicate how to display other records:
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
- **Datastore**: an application-neutral dependency used by Bookish for catalogue
  storage and synchronisation.
- **Importer**: import sessions, format-specific importers, and conversion into interchange records.
- **Lookup**: external lookup services and candidate matching.
- **App/UI**: views, navigation, editing flows, scanning, preferences, and platform integration.

Domain logic should be testable without launching the app or touching persistent stores. UI code should consume small view models or query wrappers rather than embedding persistence details deeply in views.

Bookish should adopt the project layout described in `Project Layout.md`: a thin root app target over reusable Swift packages under `Dependencies/`, with documentation, scripts, reference material, and planning notes kept under `Extras/`.

## Non-Goals

- Do not attempt to support every specialised catalogue feature before the core model is stable.
- Do not couple Bookish application features directly to a storage engine or
  synchronisation transport.
- Do not require users to understand the low-level graph/link model for common workflows.
- Do not make importers responsible for app-specific persistence decisions.

## Quality Bar

- Core transformations and import/export behavior must have focused tests.
- Views should have previews for representative empty, populated, and error states.
- Migration work must include repeatable fixtures for imported catalogue data.
- The app should make destructive catalogue operations explicit and reversible where practical.
- Documentation should stay aligned with the implemented model, especially `Catalogue Model.md`, `Datastore Design.md`, `Browser and Presentation Design.md`, and this specification.

## Open Questions

- Which import formats are required for the first usable version?
- What metadata fields are first-class versus custom properties?
- How much of the flexible graph model should be exposed directly in the UI?
