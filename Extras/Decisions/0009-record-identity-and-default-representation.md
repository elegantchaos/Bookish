# 0009: Define stable record identity and default representation

- Status: Accepted
- Date: 2026-09-03

## Context

Bookish records need a stable identity for links, mutations, and interchange,
plus consistent text and image representations for browsers, relationships, and
other contexts where a record must be recognised.

## Decision

Every Bookish record has an `id` as its stable identity. It identifies the
record in links, mutations, interchange, and other references, and is not a
user-facing display field.

Every Bookish record uses `name` as its sole persisted text display-identity
property. Bookish layouts, indexes, metadata, queries, and presentation APIs
use `name`; `title` is not part of the Bookish record schema. Importers map
source fields such as `title` to `name` at the import boundary.

A record may supply an optional `image` as its default non-textual identity.
When it has no image, its kind metadata supplies an `icon` as the standard
stand-in. Layouts and other presentation metadata may supply a more specific
stand-in when appropriate.

Records also have a `kind` property that identifies their application-level
category. Metadata records describe kinds, including their default icon and
presentation information.

## Alternatives considered

Using a mutable display property as record identity was rejected because links,
mutations, and interchange require a stable reference. Retaining `title` as a
second Bookish display identity was rejected; source-specific titles are mapped
at the import boundary. Requiring every record to carry its own image was also
rejected in favour of kind and layout fallbacks.

## Consequences

- Links and mutations retain stable identity when a user changes a name.
- The UI has predictable text and image fallbacks for every record.
- Source-specific terminology remains outside the Bookish record schema.
- Kind-level defaults stay separate from individual record data and can be
  refined through metadata.
