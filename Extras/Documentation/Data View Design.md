# Data View Design

Bookish uses a schema-less datastore so users can adapt the catalogue to their own collection. Data views define how high-level records such as books, authors, organisations, series, and lists are displayed and edited.

Data view layouts are themselves stored in the datastore. This lets users add custom fields, hide fields they do not use, choose labels and controls, and tailor the interface without changing the underlying catalogue model.

## Goals

- Present flexible records through clear, purposeful interfaces.
- Let users customise which properties are shown for each high-level record type.
- Keep display and editing behaviour data-driven where practical.
- Support custom fields without requiring a fixed schema.
- Keep UI layout decisions separate from datastore persistence.

## Layout Records

A layout record describes how to display or edit records that match a high-level type or context.

Layout records can define:
- the record types or predicates they apply to;
- the properties to display;
- the order of displayed properties;
- labels, placeholder text, and help text;
- the expected value kind for each property;
- the UI component to use for display and editing;
- whether missing values are hidden, shown as placeholders, or shown as empty controls;
- how links and ordered link lists should be presented;
- grouping, sections, and compact versus detailed presentations.

The application may provide default layout records for common types such as book, person, organisation, series, and list. Users can duplicate or customise these defaults.

## Record Types

Record types are application conventions over datastore records. A type can be indicated by one or more well-known properties, such as a type marker, role marker, or layout assignment.

The same record may be displayed through different layouts in different contexts. For example, a book may appear as:
- a compact row in a list;
- a full detail view;
- an editable metadata form;
- a relationship member inside a series or reading-history entry.

## Field Components

Field components should match the stored value and user task.

Common components include:
- text fields for strings;
- numeric fields for numbers;
- date controls for dates;
- toggles for booleans;
- image or file controls for blob references;
- pickers or navigation links for record links;
- repeatable rows for ordered lists;
- custom editors for encoded payload values when the application knows the expected type.

If the stored value cannot be decoded or coerced into the expected value kind, the view should fail gracefully and offer a raw-value or repair path where practical.

## SwiftUI Integration

SwiftUI views should read through the record service, not directly from the record store.

The record service should provide observable records, query results, and list materialisations that update when the mutation service changes the record store.

The initial design can use explicit observable wrappers or async observation streams. A SwiftData-style macro or generated helper layer can be considered later if manual observation becomes too repetitive.

## Editing Flow

Views do not write directly to the record store. Editing actions create application-level mutations through the mutation service.

The normal flow is:
- a view reads a record through the record service;
- the user edits a displayed property;
- the edit is converted into a mutation record by the mutation service;
- the mutation service stores the mutation, updates the record store, and syncs it through CloudKit;
- the record service publishes the updated materialised record back to the UI.

## User Customisation

Users should be able to:
- add custom properties to records;
- decide which fields appear for a type or context;
- rename labels without changing property keys;
- hide unused fields;
- choose specialised controls where multiple controls can edit the same value kind;
- maintain separate compact and detailed layouts.

Customisation should not require users to understand the mutation store or low-level sync model.

## Open Implementation Questions

- What is the minimal layout schema needed for the first usable UI?
- How are default layouts seeded and updated without overwriting user customisations?
- How are layout records found for a record and context?
- What observation mechanism should record service use for SwiftUI?
- How much raw-property editing should be exposed in normal views?
