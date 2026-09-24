# Kindle Library Manifest Research — 2026-09-24

## Question

Can the Kindle for macOS files copied into `Extras/Amazon/` yield a user's complete library manifest and book metadata? Is there a supported alternative?

## Local evidence

- `homefeed.json` has 13 cards and 205 book entities (176 distinct ASINs), each with an ASIN, title, primary author, and cover/detail links. Widget names identify recommendation and discovery feeds, so these entities are not evidence of ownership. None of their ASINs match the copied `eBooks/` directory names.
- `eBooks/` has 53 book directories: 35 empty and 18 with book bundles. Six directory names end in `-sample`. The 18 `BookManifest.kfx` files are SQLite databases whose tables describe bundle IDs and relative paths to content pieces. Their schema does not contain a title/author library catalogue.
- The populated bundles also contain KFX/AZW content, DRM vouchers, and `.asc` JSON files. `StartActions` includes an ASIN, content type, and cover image URL. These files can confirm local downloads, not cloud-library membership. The `.asc` files are per-book adjunct data, not a global manifest.
- `covers/` contains 371 hash-named PNGs with no demonstrated mapping from filename to ASIN or ownership.

No credential material or book text was extracted. No files under `Extras/Amazon/` were changed.

## Supported routes checked

- Amazon's Kindle help directs users to Library > All and to Manage Your Content and Devices > Books for the cloud collection. This is the authoritative user-facing list, though no official bulk manifest export was found there.
- Amazon's UK privacy notice links to **Request My Data**. A user-requested data archive may contain Kindle and order records. The actual archive format and completeness for a library manifest need testing with an export from the account.
- Amazon's Creators API exposes catalog `GetItems` and `SearchItems`, including item metadata. Its published operations do not expose a customer's Kindle entitlements or personal library. It might enrich known ASINs, subject to its access and usage terms.

## Working conclusion and next experiment

Do not treat this copied cache as a complete library. The next useful experiment is to request Amazon account data, inspect the Kindle and digital-order portions locally, and compare its ASINs against **Manage Your Content and Devices > Books**. Check purchased, borrowed, samples, personal documents, and deleted/returned items separately. If the export proves complete enough, a user-supplied archive importer is a viable Bookish feature. Local bundle parsing remains a fallback for downloaded items only.

## Sources

- [Amazon Kindle library troubleshooting](https://digprjsurvey.amazon.co.uk/csad/help/node/TsdpGRrbNmNohmj2Q9?theme=light)
- [Amazon UK privacy notice, Request My Data](https://digprjsurvey.amazon.co.uk/csad/help/node/GX7NJQ4ZB8MHFRNJ)
- [Amazon Creators API operations](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/api-reference)

## Follow-up: Library locations

A read-only search of `~/Library` located `Containers/com.amazon.Lassen`, `Group Containers/group.com.amazon.Lassen`, and a `com.amazon.Lassen.SendToKindleExtension` container, plus corresponding Application Scripts directories. No Amazon/Kindle-named top-level Application Support, Preferences, or Caches directory was found in the accessible locations; `/Library` produced no matching app-data path in the searched depth.

The `Data` directory of the main app container and the group container both returned `Operation not permitted`, including on an approved unsandboxed read-only `ls`. This appears to be macOS privacy protection, so their contents and any potential cloud-library cache remain unverified. Further inspection needs Full Disk Access for the process running Codex, or a user-supplied copy of those container contents. The copied `Extras/Amazon/` data does not settle what the inaccessible containers may contain.

## Follow-up: copied Kindle app containers

The user copied the containers into `Extras/Amazon/LibraryContainers/` and `Extras/Amazon/LibraryGroupContainers/`. This resolves the access gap above and changes the working conclusion: the main app container has a useful cached library manifest.

- `Data/Library/Protected/BookData.sqlite` (including its WAL sidecar) has 429 `ZBOOK` records: 280 books, 62 samples, 15 documents, 30 magazine issues, and 42 dictionaries. The type mapping was checked against MIME types, dictionary flags, and the separate KSDK asset cache; the KSDK cache agrees on all 280 books and 62 samples.
- Every book has a distinct ASIN, a readable title, language, and publication date. Publisher is populated for 252 books. The display-author database column is binary, but the keyed metadata archive in `ZSYNCMETADATAATTRIBUTES` provides a readable author for 279 books. One author is absent there.
- The same archive records acquisition origins. Among the 280 books, 252 carry `Purchase`, 27 carry `Sharing`, and two carry `Prime`; one book has both `Purchase` and `Sharing`. These are cache labels, not independently verified current entitlements.
- `ZRAWBOOKSTATE` is 0 for 269 books and 3 for 11. All 11 locally populated, non-sample ASINs from the earlier `Extras/Amazon/eBooks/` copy occur in the 280-book cache. This supports the interpretation that the database includes cloud entries beyond downloads, though state enum semantics are not documented.
- Both `BookData.sqlite` and `KSDK/ksdk.asset.db` passed SQLite `integrity_check`.

A private proof-of-concept JSON export of the 280 book records was written to `.build/tmp/kindle-library-manifest.json` with owner-only file permissions. It includes ASIN, title, author where available, publisher, publication date, language, origin types, and the cache's purchase date. This is a snapshot of what the Kindle app synced to this Mac, not proof of completeness against the Amazon account. The remaining check is to compare it with **Manage Your Content and Devices > Books** or an Amazon data export, especially for deleted, returned, shared, and borrowed titles.

## Follow-up: internet prior art before implementation

- [`listKindleBooks2`](https://github.com/rok-git/listKindleBooks2) independently reads the current macOS `BookData.sqlite`, `ZBOOK`, and `ZSYNCMETADATAATTRIBUTES`, exporting ASIN, title, author, publisher, and dates. It can also join Kindle collections. Its README distinguishes the old `KindleSyncMetadataCache.xml` from the current database. This directly corroborates the local extraction route.
- [Amazon's Creators API](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/api-reference) documents catalog lookup and search operations, with no customer-library operation. [Amazon's privacy notice](https://digprjsurvey.amazon.co.uk/csad/help/node/GX7NJQ4ZB8MHFRNJ) offers Request My Data, which remains a possible manual snapshot but has not been verified here as a repeatable library export.
- [Kindle web library scripts](https://github.com/MrMikey59/Kindle-Book-List) page through an internal `kindle-library/search` endpoint; [a Swift client](https://github.com/natikgadzhi/swift-kindle) also uses Kindle's internal web APIs. [Another private API client](https://github.com/Xetera/kindle-api) requires Amazon cookies and a TLS-fingerprint proxy and reports missing pagination. These routes may reach the cloud directly but depend on undocumented authentication, endpoints, and page behaviour.
- Apple's [App Sandbox file-access documentation](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox) supports read-only user-selected access through `NSOpenPanel` and persistent security-scoped bookmarks. Selecting the containing `Protected` folder should encompass the SQLite database and its `-wal`/`-shm` sidecars. Access to another app's protected container still needs a runtime test; the picker grant is not proof that every macOS privacy control will allow the read.

Recommendation for later implementation: use the local database as the primary macOS import source, with a clear schema-version/column preflight and a narrow synthetic fixture that preserves SQLite and keyed-archive structure. Keep the private full database out of Git. Reimports need stable source identity plus ASIN to update prior Kindle records; exact ASIN matches against other catalogue sources should be reconciled without silently merging ambiguous editions. This is a research recommendation, not an adopted architectural decision.
