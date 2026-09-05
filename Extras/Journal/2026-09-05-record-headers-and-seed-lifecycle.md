# Record Headers and Seed Lifecycle

Layouts now configure a standard record header through optional `titleProperty`, `subtitleProperty`, and `thumbnailProperty` values. The defaults are `name`, `subtitle`, and `image`. Record detail renders the resolved title, optional subtitle, and optional remote-image thumbnail before the property form; it no longer uses the layout name or record kind as the visible top-of-record heading.

URLs are small tagged encoded values, like dates. `BookishRecordURL` has the stable `url` kind and is accessed through `BookishRecord.url(_:)` and `setURL(_:for:)`. The Delicious importer stores its preferred cover URL in `image` and stores all cover URLs as typed values in `imageURLs`.

Configuration seed resources are imported and pruned only when the datastore lacks a seed marker. Established configuration records remain stored data across launches. `Reset Bookish Datastore` remains the explicit operation that restores bundled configuration seeds.

Index records now have an optional `icon` property containing an SF Symbol name. The browser sidebar uses that icon beside the index title, with `list.bullet` as a fallback for existing or custom indexes that do not configure one. The bundled indexes provide appropriate symbols when a datastore is first seeded or explicitly reset.

The browser's middle column displays each record as its layout-resolved thumbnail and name. When no thumbnail is available, it uses the active index's configured SF Symbol as the placeholder.

`Datastore Design.md` records the property-representation decision rule: use native JSON and datastore-plumbing cases directly, use tagged encoded values for other small domain values, and use linked records for large objects with their own identity or lifecycle.
