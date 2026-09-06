# Per-Kind Index Thumbnails

`BookishRecordPresentation.thumbnailPlaceholderSystemImage` resolves the `icon` from the effective presentation metadata for a record's `name` property. `BookishRecordIndexCell` uses it whenever the record has no header thumbnail URL, allowing a mixed-type index to show a per-kind fallback icon instead of the enclosing index icon.
