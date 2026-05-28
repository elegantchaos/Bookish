# Catalogue Model

Bookish stores a personal catalogue of books, people, organisations, series, lists, roles, and reading-related metadata.

This document describes the application-level model: the concepts the app exposes to users and higher-level features. The lower-level persistence, sync, mutation, and local storage design is described in `Datastore Design.md`.

## Records

A record is the base unit of catalogue data. Records have stable identifiers, display names, flexible properties, and links to other records.

The model is intentionally schema-less. High-level types such as book, person, organisation, series, list, role, and relationship are represented by conventions over records and their properties rather than by fixed storage tables.

Typical record properties include:
- display name;
- type or role markers;
- identifiers such as ISBNs;
- dates, notes, ratings, and other metadata;
- references to related records;
- blob references for cover artwork or other large payloads.

Records are tombstoned rather than deleted so that destructive operations can be reversed where practical and synchronisation can remain deterministic.

## Core Entities

Bookish has a small set of user-facing record categories:

- **Book**: the central catalogue item, with title, identifiers, authors, publisher, publication details, cover artwork, and user fields.
- **Person**: an author, illustrator, editor, narrator, contributor, owner, or other individual connected to books.
- **Organisation**: a publisher, imprint, retailer, library, or other institution.
- **Series**: an ordered or semi-ordered group of books.
- **List**: a user-managed collection such as wishlist, owned, loaned, favourites, imports, or reading history.
- **Role**: the semantic meaning of a relationship, such as author, illustrator, publisher, owner, read, or wishlist item.

These categories are application conventions. A record may be interpreted through more than one category when the application has a reason to do so.

## Links And Relationships

Records can link to other records to form a graph. Simple properties can contain direct record links or ordered lists of record links.

Relationships that need metadata should be represented as records themselves. A relationship record can connect two or more records and carry properties such as:
- role;
- ordering;
- dates;
- notes;
- source;
- status;
- relationship-specific user fields.

This allows common cases, such as book-to-author links, to stay simple while supporting richer cases such as reading history entries, loans, ownership details, and repeated appearances in a list.

## Lists

Lists are ordered or unordered collections of records. A list can contain direct record links for simple cases, or relationship records when entries need their own metadata.

The same target record may appear in multiple lists or multiple times within the same list. If a workflow requires uniqueness, that rule should be enforced by the application layer rather than by the low-level datastore.

Series are a specialised list-like concept where order is part of the meaning of the relationship.

## Import, Export, And Interchange

Importers should transform external data into storage-neutral records before touching the application datastore. Export should use the same application-level record model where possible so catalogue data remains portable and testable outside the user interface.

Bookish interchange files and Delicious Library-style data remain important import/export inputs, but the catalogue model should not depend on any one external format.

## Data Views

The flexible catalogue model requires flexible display and editing. User-facing layouts, field choices, labels, and controls are described in `Data View Design.md`.

Data views sit above the catalogue model: they decide how records are presented, not how records are persisted.
