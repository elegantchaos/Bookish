# Configuration Record Provenance

Configuration records do not represent user-supplied data, so indexes and seed markers no longer store a `source` property. The seeded layouts for `layout`, `index`, and `seedMarker` likewise omit the source field. User-facing/imported record layouts retain it.
