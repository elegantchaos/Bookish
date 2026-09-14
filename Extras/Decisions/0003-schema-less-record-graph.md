# 0003: Model the catalogue as a schema-less record graph

- Status: Accepted
- Date: 2026-05-28

## Context

Bookish represents books alongside people, organisations, series, lists, roles,
relationships, layouts, and presentation metadata. The catalogue must support
new properties and relationship shapes without requiring storage-schema changes
for each feature.

## Decision

A record is the base unit of catalogue data. Records have stable identifiers,
a display name, flexible named properties, and links to other records.

Catalogue concepts such as `book`, `person`, `organisation`, `series`, `list`,
`role`, and `relationship` are application-level conventions over records, not
fixed persistence tables. Links form a directed graph. Common connections use
direct record links or ordered lists; a relationship record is used only when a
connection needs its own metadata.

Storage remains independent from catalogue semantics. Metadata-driven layouts
and presentations decide how records are displayed, rather than changing the
underlying record model.

## Consequences

- New catalogue fields and kinds can be introduced without datastore migrations.
- Importers and exporters share a storage-neutral record representation.
- Relationship metadata is explicit only where it adds value.
- Application code must define and validate the conventions that give records
  their meaning.
