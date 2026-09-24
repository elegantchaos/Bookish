# Kindle local database importer — 2026-09-24

## Work

- Implemented `BookishImporter` extraction from Kindle for Mac's `BookData.sqlite`. The importer accepts a normal file URL or the containing folder URL, reads books from `ZBOOK`, decodes the keyed sync metadata for ASIN and author, and emits Bookish book/person/organisation records. It excludes samples, documents, magazines, and dictionaries by Kindle's raw type code.
- Added a synthetic, four-row SQLite fixture with two books, a sample, and a dictionary. It preserves the observed SQLite columns and `NSKeyedArchiver` structure, and contains no user library data.
- Added a macOS import command in BookishApp. `NSOpenPanel` starts in the Kindle container's `Protected` folder. The selected folder's security scope stays active while SQLite reads the database and sidecars. Runtime permission behaviour still needs testing in the sandboxed app.
- Repeat imports pass existing Kindle-sourced record IDs to the importer. Stable Kindle book IDs derive from ASIN; related person and organisation IDs derive from names. Already imported records are skipped, so a later run emits new titles and relationships only. Existing Kindle records are currently left as they were even if Kindle's metadata changes.

## Matching work to revisit

- Source-scoped repeat detection is deterministic. Cross-source matching needs a separate candidate process: an ASIN/ISBN match can suggest the same edition, while title/author matches can be ambiguous. A physical second copy must remain addable by choice.
- Barcode and shelf capture should show existing catalogue candidates before adding a record. This is a UI decision point, with the option to add another copy. It cannot simply apply the Kindle importer's skip rule.
- Cleanup should find and review possible duplicates for books and other record kinds. The existing review-first cleanup decision applies; bulk automatic merging would risk losing identity and relationships.
- `BookishLookup` can enrich sparse metadata before comparison, but provider results need provenance and should not overwrite user edits silently. No shared matching API or policy was introduced in this importer.
- Kindle's schema and cache coverage remain undocumented. Compare imported titles against the account library, and add diagnostics/tests for schema changes as they appear.
