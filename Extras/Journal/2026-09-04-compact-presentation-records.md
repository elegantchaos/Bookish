# Compact Presentation Records

- Replaced the metadata wrapper record with direct `presentation.type.*` records.
- Store individual `BookishPropertyPresentation` values as encoded record properties.
- Encoded dictionaries are now untagged by default and may retain an optional unknown kind hint through the active interchange `rvKey`.
- Changed interchange defaults to `ℹ` for record IDs, `©` for record kinds, and `®` for tagged values.
- Schema declarations now include only non-default fields; `PresentationSeed` retains its `layout` default while `SampleSeed` needs no schema.
