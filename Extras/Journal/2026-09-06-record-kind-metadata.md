# Record Kind Metadata

`metadata` is a configuration record kind for type-level display data. `MetadataSeed.bookish.json` defines records for each known Bookish kind plus a wildcard fallback. Each record has a display name, an SF Symbol `icon`, an advisory `types` list, and a `presentation` link to a fixed presentation seed record.

`BookishHarness.recordKindMetadata(for:)` resolves exact metadata first and falls back to `metadata.type.*`. Presentation resolution, record-link thumbnails, and mixed-type index thumbnails use this metadata rather than reusing index icons or field-label icons. The configuration seed import installs `MetadataSeed` for existing seeded datastores as well as new ones.

The browser includes debug-only Metadata and Presentations indexes, both using the all-fields layout. The extracted command files now use standard source headers dated from their original definitions: most on 01/09/2026, index-navigation commands on 02/09/2026, and projection rebuild on 04/09/2026.
