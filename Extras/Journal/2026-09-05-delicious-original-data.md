# Delicious Original Data Preservation

The Delicious Library importer now stores each accepted source property-list dictionary as deterministic JSON in `originalData`. Property-list dates are represented as ISO 8601 strings, and the importer accepts those strings when reading date fields, preserving the data needed to re-run future importer revisions.

`originalData` is the sole preservation mechanism: the former duplicate `original.*` properties are not emitted.

The Bookish record date keys are now `added`, `modified`, and `published`. Their Swift constant names remain `addedDate`, `modifiedDate`, and `publishedDate` to make their value type explicit.

The legacy `BookKey` adapter also uses the canonical `name` key; it has no `title` key case.
