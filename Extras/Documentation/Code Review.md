# Code Review

A full review of the Bookish codebase at `main` commit `e1b56be` (2026-09-25), written as if the whole repository were one pull request.

It checks the code against the shared skills in `elegantchaos/Agents` (commit `7ae1d2b`): `baseline:standards`, `swift:language`, `swift:swiftui`, `swift:concurrency`, `swift:testing` and `swift:swiftdata`. It also checks the project's own rules in `AGENTS.md` and the decision log.
Emphasis is on SwiftUI performance and on concurrency and `async`/`await`.

**Scope:** the host app (`Sources/Bookish`), the ten packages under `Dependencies/` that this repository owns, and their tests. Submodules (`Application`, `Commands`, `Icons`, `Keychain`, `Logger`, `Settings`) and `Extras/Legacy` are out of scope.

**Method:** the code was read, not built. This environment has no Swift toolchain, so nothing was compiled, tested or profiled. Performance findings come from reading the code paths, not from measurement.
Items that the journal already records as known or deferred are marked **(known)**, with a link. They are included where the review adds a concrete consequence or a cheaper interim fix.

## Path abbreviations

| Prefix | Path |
| --- | --- |
| `App/` | `Dependencies/BookishApp/Sources/BookishApp/` |
| `DS/` | `Dependencies/BookishDatastore/Sources/BookishDatastore/` |
| `RV/` | `Dependencies/BookishRecordView/Sources/BookishRecordView/` |
| `Imp/` | `Dependencies/BookishImporter/Sources/BookishImporter/` |
| `Rec/` | `Dependencies/BookishRecognition/Sources/BookishRecognition/` |
| `Look/` | `Dependencies/BookishLookup/Sources/BookishLookup/` |
| `Cl/` | `Dependencies/BookishCleanup/Sources/BookishCleanup/` |
| `BR/` | `Dependencies/BookishRecord/Sources/BookishRecord/` |
| `Cod/` | `Dependencies/BookishCoding/Sources/BookishCoding/` |

## Severity key

- 🔴 **High**: incorrect behaviour, data loss or divergence, or a cost that grows without bound as the app is used.
- 🟠 **Medium**: a noticeable performance cost, a latent bug, or a clear departure from the skills or the decision log.
- 🟡 **Low**: modernisation, consistency, style and hygiene.

---

## 1. Summary

This is a well-structured modern codebase.
It has a thin host app, focused packages, `Sendable` value-type models, Swift Testing throughout with no sleeps or network access, `#Preview`s, `ContentUnavailableView`, and `@Observable @MainActor` service state following Decision 0022.
Documentation comments are present on most declarations. `BookishLookup` is a model of structured concurrency: a task group with per-provider failures.

Most of the significant findings are in two places: **how record changes reach the UI**, and **how the datastore applies mutations**. The journal already plans to replace the first ([Fine-Grained Record Observation](../Journal/2026-09-25-fine-grained-record-observation.md)). This review adds concrete problems that happen today, and cheaper interim fixes.

### Most important findings

1. **Query results grow without bound as the app is used (P1, 🔴).** Each keystroke in the index filter, and each record detail with a query section, creates a new `RecordQueryResult` that the datastore keeps for ever. Every mutation re-runs every one of them against the whole store. The journal notes that results are never released, but not that ordinary typing and browsing create them.
2. **Mutations can lose updates (A1, 🔴).** `DefaultMutationService` does read-modify-write across two actors with `await`s in between, and nothing serialises it. Overlapping commands can drop a property from the projection or apply mutations out of order.
3. **Seeding bypasses the mutation log (C1, 🔴).** Seed and sample records are written directly to the record store. As a result, rebuilding the projection brings back sample records the user deleted, relaunching overwrites edits to metadata and query-section records, and seeds can never sync.
4. **Imports do heavy work on the main actor (A3, P5, 🟠).** Reading the whole file, O(N×M) reconciliation, and a full-catalogue comparison all run on `@MainActor`. Applying an import then issues one mutation per record, and each one refreshes every live query result.
5. **The whole detail view reloads on every change (P2, 🟠, partly known).** One status change reloads the record, the layout, the presentations, every section, every linked-record button and every query section, each with several actor hops.
6. **Presentation resolution decodes JSON in `body` (P3, 🟠).** Layout items, headers, index queries and date sort keys decode JSON through a newly created `JSONDecoder` on every evaluation, including per list row and per sort comparison.
7. **The index filter can drop keystrokes (U1, 🟠).** `.searchable` is bound to an async, command-backed `Binding(get:set:)`, so the field can briefly revert while the command runs.
8. **Nothing is localised yet (L1, 🟠).** There are no string catalogues anywhere, although the project layout calls for module-owned `.xcstrings`.

---

## 2. Correctness and data integrity

### 🔴 C1: Seeds are written to the projection, not the mutation log
`App/Services/BookishStorageService.swift:127-142, 195-212, 215-232, 254-263`

`seed()` imports bundled configuration and sample records with `datastore.recordStore.upsert`, prunes them with `recordStore.delete`, and writes the seed marker straight to the record store.
[Decision 0002](../Decisions/0002-mutation-log-and-record-projection.md) makes mutations canonical and the record store a projection. Consequences:

- **Rebuilding brings back deleted sample records.** `rebuildRecordProjection` deletes the record store and replays mutations. A user's `deleteRecord` for a sample book replays as a no-op, because the book was never in the log. Then `seed()` finds no marker and imports `SampleSeed` again.
- **User edits to seed records are overwritten.** On every normal launch, `MetadataSeed` and `QuerySectionSeed` are upserted over whatever the projection holds. On rebuild, a replayed `setProperty` on a configuration record creates a stub (`MutationService.swift:89-93`) that the seed then replaces. Today users can't edit these records, but layouts and presentations are meant to be user-customisable.
- **Seeds can't sync**, so every device creates its own copy.
- **Query results aren't refreshed.** Direct record-store writes don't call `projectionDidChange`, so results are only correct because `load()` and `reset()` call `replaceStore` afterwards.

`addMissingSeedIndexCreationTypes()` does go through the mutation service, so the codebase uses both approaches.

**Fix:** seed through mutations (one `upsertRecord` batch, see A2), keyed so that it is idempotent. Or record a decision that configuration seeds are a separate, non-synced layer, stored and replayed separately from user mutations.

### 🟠 C2: Recognised books lose their authors
`App/Extensions/BookRecognitionCandidate+BookRecord.swift:11-16`

`bookRecord` keeps only the title and drops the authors and confidence the recogniser returned.
It also creates a new random ID each time, so adding the same candidate twice creates two books.
**Fix:** create person records and links as the importers do (deterministic IDs, `source`/`importedID`), and run the result through `BookishImportReconciler` so duplicates go to review.

### 🟠 C3: Late recognition results overwrite newer state
`App/Services/BookishRecognitionService.swift:134-146, 116-121`

`identifyBooks()` awaits the provider and then assigns `state.candidates` without checking whether the image changed in the meantime.
If the user picks a new image while a slow provider (Cloud Compute or OpenAI) is running, the old image's candidates appear against the new image.
`CaptureBooksCommand` is disabled while recognising, but `selectImage` isn't.
**Fix:** keep the request's `imageData` (or a generation counter), and after the `await` drop the result if it no longer matches. Better: run recognition in a `.task(id:)`, or keep and cancel the in-flight `Task`.

### 🟠 C4: Delicious import can merge distinct books
`Imp/DeliciousLibraryImporter.swift:205-206, 299-322`

If a source record has neither `uuidString` nor `foreignUUIDString`, its ID falls back to `"delicious-import-\(title)"`. Two different editions with the same title then get the same ID, and `store()` silently replaces the first.
**Fix:** include more distinguishing fields (ISBN, ASIN, format) in the fallback. At minimum, record a diagnostic when an ID collides.

### 🟡 C5: Smaller correctness points
- `BookishEncodedValue` (`BR/BookishEncodedValue.swift:148-157`) and `BookishInterchangeCodec.decodeValue` (`Cod/BookishInterchangeCodec.swift:208-218`) turn any whole-valued `NSNumber` into `.integer(value.intValue)`. Values above `Int.max` (for example `1e20`) silently wrap, and a stored `2.0` comes back as an `Int`. Check `double.magnitude < 2^63`, and share one implementation (see S5).
- `BookishRecordValue(date:)` encodes with ISO-8601 without fractional seconds (`BR/BookishRecordCoding.swift:11-15`), so `record.date(key)` returns a different `Date` from the one stored. Two edits within the same second then sort as equal. Use a format with fractional seconds, or store `timeIntervalSinceReferenceDate`.
- `OpenAIResponsesBookRecognitionProvider` (`Rec/Providers/OpenAIResponsesBookRecognitionProvider.swift:99`) always labels the image `image/jpeg`, even for HEIC or PNG input from Photos or files.
- `KindleDatabase.init` (`Imp/KindleLibraryImporter.swift:83-87`) doesn't close the handle when `sqlite3_open_v2` fails. SQLite allocates a handle even on failure.
- `BookishExportingService.hasExportableRecords` checks the *visible* records, but the export writes *every* record (`App/Services/BookishExportingService.swift:39-43, 84`).
- `ImportKindleLibraryCommand` has no platform availability, and `requestKindleLibraryImport()` does nothing on iOS after switching to the Import section (`App/Services/BookishImportingService.swift:207-224`).

---

## 3. Concurrency and `async`/`await`

### 🔴 A1: The mutation service isn't serialised
`DS/MutationService.swift:40-106`

`DefaultMutationService` is a `Sendable` struct with no isolation. Each mutation awaits `mutationStore.append` → `isApplied` → `recordStore.record(id:)` → `recordStore.upsert` → `markApplied`, which are suspension points on two different actors.
Commands run concurrently (`performWithoutWaiting`), so two mutations on the same record can interleave:

- **Lost update:** mutation A sets `status` and mutation B sets `note`. Both read the old record and both upsert, so the second upsert removes the first property from the projection. The log still has both, so the projection no longer matches the log until a rebuild.
- **Order inversion:** clicking Mark Reading and then Mark Finished can leave the projection at "Reading".
- **Check-then-act:** two deliveries of the same remote mutation can both pass `isApplied` (actor reentrancy across actors).

**Fix:** make one actor own apply-and-mark, for example a `MutationService` actor, or a single `apply(_:)` on the record store that does the read-modify-write without suspending. Add a test that runs concurrent `setProperty` mutations on one record.

### 🟠 A2: No batch mutation API, so imports apply one record at a time
`App/Services/BookishStorageService.swift:71-76`, `DS/MutationService.swift:47-53`, `DS/BookishDatastore.swift:35-37`

`upsert(records:)` performs one mutation per record. Each one writes a mutation file, an applied marker and a record file, then calls `refreshResults()`, which filters and sorts the whole store once for every cached result.
Applying a Delicious Library import (about 1,400 books plus people, organisations and series) therefore does thousands of full-store query refreshes. **(Known in outline:** the journal notes quadratic imports and asks for coalesced notifications.)
**Interim fix:** add `perform(_ operations: [MutationOperation])`, which appends and applies them all and refreshes once. This is small, fits the planned design, and also removes the per-record `projectionDidChange` hops in C1's seeding.

### 🟠 A3: Heavy import work runs on the main actor
`App/Services/BookishImportingService.swift:374-420, 425-442`

`BookishImportingService` is `@MainActor`, so these all run on the main thread:

- `Data(contentsOf: url)` for the source file (the full Delicious sample is 6.9 MB);
- `storageService.records(matching: RecordQuery())`, which copies and sorts the whole catalogue;
- `BookishImportReconciler().plan(...)`: for every new record, `existing.filter { isPossibleMatch }`, which folds and compares name strings on both sides. That is O(N×M) string folding (`Imp/BookishImportReconciler.swift:32, 66-95`);
- `apply()`, which fetches the whole catalogue again and compares two full-catalogue dictionaries for equality to detect changes.

**Fix:**
- Pass the URL to the importer and read the file inside it.
- Make the reconciler build indexes by ASIN, ISBN and match key once, and run it off the main actor, as a `nonisolated` `@concurrent` function or in an actor.
- Detect catalogue changes with a cheap datastore revision (mutation count or head) instead of comparing whole catalogues.

### 🟠 A4: `Task.detached` and a repeated streaming skeleton in the importers
`Imp/DeliciousLibraryImporter.swift:25-88`, `Imp/KindleLibraryImporter.swift:28-77`, `Imp/BookishInterchangeImporter.swift:27-71`

All three importers repeat the same pattern: `makeStream`, then `Task.detached`, then `do`/`catch CancellationError`, then `onTermination { task.cancel() }`.
The package isn't main-actor-isolated by default, so `Task.detached` here is a deliberate way to get parsing off the caller's actor. The concurrency skill says `Task.detached` is rarely right, and Swift 6.2 has `@concurrent` for this.
**Fix:** factor out one helper, such as `func makeImportStream(_ body: @Sendable @concurrent (Continuation) async throws -> Void) -> AsyncThrowingStream<…>`, with a named task. Consider a bounded buffer for `.progress` events, since there is one per source item and the consumer is on the main actor. `.records` batches must not be dropped, so keep them in a separate channel or use `bufferingOldest` with care.

### 🟠 A5: CPU-heavy provider work doesn't say where it runs
`Rec/Providers/OCRBookRecognitionProvider.swift:34`, `Rec/BookImageTextExtractor.swift:12-22`, `Rec/BookImageLoader.swift`

Vision OCR and image decoding are synchronous work inside `nonisolated async` functions.
Today the packages don't use `NonisolatedNonsendingByDefault`, so this runs on the global pool.
If the recommended Swift 6.2 settings are adopted (S1), the same code will run on the caller's actor, which is the main actor, and freeze the UI.
**Fix:** mark these functions `@concurrent`, or move to the async Vision API (`RecognizeTextRequest().perform(on:)`).

### 🟡 A6: Other concurrency points
- `BookRecognitionImagePreview.loadPreviewImage()` (`App/Views/BookRecognitionImagePreview.swift:45-52`) awaits a `Task.detached` inside `.task`. Cancelling the view's task doesn't cancel the detached decode. Use a `@concurrent static func`.
- `requestKindleLibraryImport()` uses `NSOpenPanel.begin` with a completion handler plus an unstructured `Task` (`App/Services/BookishImportingService.swift:219-222`). Use `.fileImporter` with `allowedContentTypes: [.folder]`, like the other import sources. That also keeps AppKit out of a service.
- `RecordQueryResult` has two notification mechanisms: `@Observable` properties and a separate `observeRecords` callback registry (`DS/RecordQueryResult.swift:30, 52-61`). Navigation uses the callback to reconcile selection. Consider an `AsyncStream` of membership changes, or `withObservationTracking`, so there is one mechanism.
- `DefaultRecordQueryService.result(matching:)` does a linear scan with an `await` to the main actor for each cached result (`DS/RecordQueryService.swift:28-35`). Make `RecordQuery` `Hashable` and key a dictionary by query.
- `JSONRecordStore` and `JSONMutationStore` do synchronous file I/O on their actors, which ties up cooperative threads during bulk writes. That's acceptable for a JSON prototype; keep it in mind for the SQLite store.
- `processPendingMutations()` replays in `createdAt` order, but live application uses arrival order. Once remote mutations can arrive late, a rebuilt projection can differ from the live one. This is noted for the sync design, not as a bug today.
- The test helper `ObservedChanges` is an `@unchecked Sendable` class with an unsynchronised `var` (`Dependencies/BookishApp/Tests/BookishAppTests/BookishAppTests.swift:899-907`). Use `Mutex<Int>`.
- `BookRecognitionProviderRegistry` is a non-`Sendable`, unisolated class with mutable state, while the equivalent `BookLookupService` is an actor (`Rec/BookRecognitionProviderRegistry.swift`). It is only used from the main actor, so it is safe today. Use one approach for both.

---

## 4. SwiftUI performance audit

### 🔴 P1: Filter keystrokes and query sections create query results that are never released
`App/Services/BookishNavigationService.swift:254-262, 342-364`, `DS/RecordQuery.swift:44-55`, `DS/RecordQueryService.swift:28-55`, `App/Views/RecordQuerySectionView.swift:115-117`

- Each change to `.searchable` runs `SetRecordNameFilterCommand`, which calls `recordQueryResult(matching: query.filteringNames(containing: filter))`. Each distinct filter string is a new `RecordQuery`, so a new `RecordQueryResult` is added to `results` for good. Typing "tolkien" leaves seven permanent results.
- Each record detail with a query section (for example "books by this author") resolves a host-specific query, which is another permanent result per host record visited.
- `refreshResults()` re-runs **every** cached result, a full filter and sort of the store, after **every** mutation.

So the cost of each mutation grows with how much the user has typed and browsed since launch, and memory grows too. **(Known in part:** the journal notes that results are never released, but not that filtering and browsing create them.)

**Interim fix, until fine-grained observation lands:** release results that nothing observes (weak references in the service, or explicit `release` when the owning view or selection changes). Also, don't cache filtered queries at all: filter the observed base result in memory, or reuse one result per index whose query is replaced when the filter changes.

### 🟠 P2: One change reloads the whole detail view **(known)**
`App/Services/BookishBrowserService.swift:86-92`, and the `.task(id:)` keys in `App/Views/BookishRecordIDDetail.swift:98-100`, `RecordLayoutItemView.swift:102-104`, `RecordLayoutSectionView.swift:74-76`, `RecordQuerySectionView.swift:90-92`, `RecordLinkButton.swift:54-56`, `RecordIndexView.swift:99-101`

The journal covers the design. For scale, one "Mark Reading" currently triggers:

- a navigation index refresh;
- a presentation refresh;
- then, because of `revision`:
  - a record, layout and presentations reload, with up to 6 storage-actor round trips;
  - per section, a record reload plus presentations (3–5 round trips);
  - per linked-record button, a record lookup plus kind metadata (2–3 round trips);
  - per query section, a record lookup, a new query result (P1), and metadata for each result kind.

The query section's `RecordQueryResult` is already observable and would update by itself. Keying it on `revision` too does the work twice.

**Interim fix:** leave `revision` out of `RecordQuerySectionView`'s key. Have `BookishPresentationService.State` cache resolved presentations and kind metadata (they only change when configuration records change), so detail views stop refetching them.

### 🟠 P3: JSON decoding in `body` and in sort comparators
- `CascadingPresentationResolver.presentation(for:)` (`RV/PresentationResolver.swift:32-57`) decodes `BookishPropertyPresentation` from every presentation record on every call. `BookishRecordPresentation.layoutItems(for:)` calls it twice per key (`field(for:)` and `label(for:)`), and `layoutItems` is computed in `body` by `BookishRecordFieldsView`, `BookishRecordCell.summary` (per row) and `RecordLayoutSectionView` (twice per body, `App/Views/RecordLayoutSectionView.swift:37-51`).
- `BookishValueViewerRegistry.nativeIdentifier` tries to decode a `BookishPropertyPresentation` from every `.encoded` value to choose a viewer (`RV/BookishValueViewerRegistry.swift:63-64`).
- `BookishRecordPresentation.header` decodes the thumbnail URL. `BookishRecordView.body` reads `header` three times (`RV/BookishRecordView.swift:33-46`), and every `BookishRecordIndexCell` reads it.
- `BookishRecordIndex.query` decodes JSON on every access (`App/BookishRecordIndex.swift:30-32`). `canCreate` (used for command availability in toolbars and menus) calls it for every library index on every evaluation (`App/Services/BookishRecordCreationService.swift:86-98`).
- `RecordSortDescriptor.compare` checks `dateValue` on both operands before anything else (`DS/RecordSortDescriptor.swift:130`). For encoded values that means two `JSONSerialization` + `JSONDecoder` round trips per comparison, so sorting by a date is O(n log n) JSON decodes. `BookishRecordCoding.makeDecoder()` also creates a new decoder every time.

**Fix:**
- Decode once: have `CascadingPresentationResolver.init` pre-merge a `[String: BookishPropertyPresentation]`.
- Compute a presentation's layout items once (a stored `let` built in `init`, or cached by the parent). View `init`s must stay trivial, so do this in the parent or in presentation state, not in the view's `init`.
- Parse `BookishRecordIndex` into stored fields when it is built.
- Pre-compute sort keys (a decorate-sort-undecorate pass), or store dates in an efficient form (C5).

### 🟠 P4: Row views rebuild resolvers and use `AnyView`
- `RecordIndexView` builds a new `CascadingPresentationResolver` (scanning and filtering presentations) for every row on every body evaluation (`App/Views/RecordIndexView.swift:40-52`). Build one resolver per kind in `loadPresentation()` and store it.
- `BookishValueViewerRegistry.view(for:mode:)` returns `AnyView` for every field (`RV/BookishValueViewerRegistry.swift:30-53`), and `RecordLinkView` is `(BookishRecordID) -> AnyView`. The app wraps `RecordLinkButton` in `AnyView` twice (`App/Views/BookishRecordIDDetail.swift:55-59`, `RecordLayoutSectionView.swift:53-57`). Replace with a `@ViewBuilder` `switch` returning `some View`, and make the registry generic over the link view type.
- `BookishListValueView` uses `ForEach(Array(values.enumerated()), id: \.offset)` (`RV/BookishValueViewerRegistry.swift:100`), which both copies into an array and uses offsets as identity. Both are on the skill's list to avoid. Use `ForEach(values.enumerated(), id: \.offset)` only for truly static lists; for record links, identify by the linked ID.
- `BookishRecordFieldsView` produces two optional `if case` views per layout item (`RV/BookishRecordFieldsView.swift:31-47`), so each row isn't unary. Use one `switch item`.

### 🟠 P5: Status bar recomputes on every progress event
`App/Views/BookishStatusBar.swift:33`

`Text("\(navigation.recordIDs.count) records")` maps every record in the selected result to its ID on every status bar body. The status bar re-renders on each import progress event, one per source item.
**Fix:** use `selectedRecordResult?.records.count`, and use inflection (`^[\(count) record](inflect: true)`).

### 🟡 P6: Other SwiftUI efficiency points
- `BookishRootView` switches between two different `NavigationSplitView`s depending on `selectedMainSection` (`App/Views/BookishRootView.swift:40-45`). Choosing a workflow destroys and rebuilds the sidebar, losing its scroll and selection state. Use one split view and switch the content and detail columns.
- `RecordQuerySectionView` lays out every result row eagerly in a `VStack` inside one form row (`App/Views/RecordQuerySectionView.swift:51-82`). A publisher or series section can have hundreds of rows. Emit the rows directly as `Section` content so the `Form` can be lazy, or cap the list with a "Show all" link.
- `BookishImportReviewView.init` builds a dictionary of the whole catalogue (`App/Views/BookishImportReviewView.swift:17-21`). Its body calls `reviewEntries`, `newCount` and `skippedCount`, each an O(n) filter. Each `BookishImportReviewRow` reads `importing.importChoices[entry.id]`, so every row observes the whole dictionary and changing one choice re-renders all rows. Precompute counts and the lookup on the plan, and pass each row its choice (or a focused binding).
- `RecordIndexView.loadPresentation()` assigns to `@State metadataByKind` inside a loop, invalidating once per kind, and never clears stale kinds (`App/Views/RecordIndexView.swift:104-119`). Build a local dictionary and assign it once, as it already does for `presentationsByKind`.
- `BookishRecordFieldsView` and `BookishRecordView` store an escaping `sectionView` closure. That's justified here because it's a function of the section ID, but prefer making the section view a generic type parameter built from the ID, so SwiftUI can compare inputs.
- `AsyncImage` in index rows and thumbnails (`RV/BookishRecordThumbnail.swift`, `BookishRecordHeaderView.swift`) relies on the shared `URLCache`. On SDK 27, `AsyncImage` caches over HTTP by default; until the baseline is raised, consider a small shared image cache for scrolling lists.

---

## 5. SwiftUI API and patterns

### 🟠 U1: Command-backed `Binding(get:set:)` on text and selection
`App/Views/RecordIndexView.swift:81-96`, `App/Views/BrowserIndexListView.swift:72-82`, `App/Views/BookCaptureCandidateList.swift:76-89`

The `.searchable` text binding's setter dispatches `SetRecordNameFilterCommand` asynchronously, and its getter reads `navigation.recordNameFilter`, which only changes when that command's task runs. While typing, SwiftUI can read the old value back, so the field briefly reverts or drops characters **(verify by typing quickly)**.
This also contradicts [Command and Environment Design](Command%20and%20Environment%20Design.md#view-rules): "do not replace a native binding with an ad-hoc command-backed binding".
**Fix:** keep the text in view `@State`. Run the filter command in `.task(id: text)` (with a short debounce) or in `.onChange(of:)`. For list selection, either use the documented direct-binding exception or keep local selection state and dispatch the command from `.onChange`.

### 🟡 U2: Other API points
- `BookLookupView` uses `TextField("", text:)` (`App/Views/BookLookupView.swift:25`), which gives the field no accessible label. Use `TextField("Search", text:, prompt:)`. `.disableAutocorrection(true)` is deprecated; use `.autocorrectionDisabled()`.
- The provider menus in `CaptureSettingsView` and `LookupSettingsView` mark the current choice with `Image("checkmark").opacity(0 or 1)` (`App/Views/Settings/CaptureSettingsView.swift:30-43`, `LookupSettingsView.swift:25-38`). VoiceOver still reads the hidden check marks, and the menu has no selected state. Use `Picker(selection:)` with `.pickerStyle(.menu)`, which the direct-binding exception allows, and route the change through the selection command in `.onChange`.
- `RecordLayoutItemView` and `RecordQuerySectionView` declare `@AppStorage(.featureMode) var featureMode` without `private`, and use computed `@ViewBuilder` properties for diagnostics. Move the diagnostics into small views.
- `BookishMainSection.placeholderDescription` has text for all four workflows, but only Cleanup still uses it (`App/BookishMainSection.swift:53-64`).
- `NavigateToRecordCommand.Mode.bestIndex` is public but always disabled and always throws (`App/Commands/NavigateToRecordCommand.swift:23, 49-50, 74-75`). Remove it until it's implemented (YAGNI).
- `BookishInterchangeDocument` declares readable content types but is only used for export (`App/BookishInterchangeDocument.swift`).

---

## 6. Swift language, standards and project configuration

### 🟠 S1: Toolchain and concurrency settings disagree
- [Decision 0011](../Decisions/0011-modern-apple-platform-baseline.md) says Swift **6.4+** and **26.0** minimum targets. The packages use `swift-tools-version:6.3` with `.macOS(.v26), .iOS(.v26)`, `Settings.xcconfig` sets `SWIFT_VERSION = 6.0` with **26.5** targets, and the app target in `project.pbxproj` overrides this with `SWIFT_VERSION = 6.3`. The project-level configurations still carry `IPHONEOS_DEPLOYMENT_TARGET = 14.0` and `MACOSX_DEPLOYMENT_TARGET = 11.1` (`project.pbxproj:306-307, 366-367`).
- The app target enables `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and an experimental flag (`SendableProhibitsMainActorInference`). No package sets any Swift settings. The app target contains one file, so the setting affects almost nothing, while `BookishApp` (all UI and services) annotates `@MainActor` by hand.

**Fix:** align these with the decision in one place: one tools version, one deployment target, and `swiftSettings` in each manifest. Consider `.defaultIsolation(MainActor.self)` for `BookishApp` and `BookishRecordView`, and nonisolated defaults plus `NonisolatedNonsendingByDefault` for the model and importer packages. That change interacts with A5, so mark CPU-heavy functions `@concurrent` first. Record whether shipping with the experimental flag is intended.

### 🟠 S2: Dependencies
- `BookishCleanup` and `BookishRecognition` depend on `Logger` by URL, while `Logger` is a submodule and other owned packages use local paths. [Decision 0012](../Decisions/0012-thin-host-and-package-first-architecture.md) expects local overrides during coordinated development. `BookishRecognition` declares `Logger` but never uses it.
- `StarWarsView` isn't referenced by the Xcode project or by any package. Either wire it in (the intro crawl) or move it out of `Dependencies/`. Its text has typos ("furrough", "Skeumorphism", "I so I started").
- `AGENTS.md` says "use SwiftData only within the datastore implementation". [Datastore Implementation](Datastore%20Implementation.md) and [Datastore Design](Datastore%20Design.md) say *not* to use SwiftData and to use raw SQLite. The current store is JSON. Reconcile the two so the next storage step follows the intended rule. The `swift:swiftdata` skill isn't applicable yet.

### 🟠 S3: Compatibility shims the project said to ask about
`DS/JSONMutationStore.swift:5-8, 90-132`, `DS/JSONRecordStore.swift:99-121`, `DS/BookishDatastore.swift:47-54`, `App/Services/BookishStorageService.swift:240`

The stores still migrate the old single-file `records.json` and `mutations.json` formats, and seed pruning still recognises the old kind `"recordIndex"`.
`AGENTS.md` says to ask before adding migrations or shims, since there is one user. Confirm whether these are still needed, and remove them if not.

### 🟡 S4: File organisation and headers
- The standard header is missing from 38 of 214 source files: most of `DS/`, the import-plan files in `Imp/`, several `RV/` and `App/` views and commands, and `Sources/Bookish/Application.swift`. `Cl/` still uses the old "All code (c)" header.
- Several files declare more than one type: `Imp/BookishImporter.swift` (6 types), `Imp/BookishImportPlan.swift` (6), `Imp/KindleLibraryImporter.swift`, `Imp/DeliciousLibraryImporter.swift`, `Cl/SeriesDetector.swift` (9 classes), `DS/RecordSortDescriptor.swift` (3 public types), `DS/MutationRecord.swift` and `Rec/BookRecognitionCandidate.swift`.
- Nested types come before the main members in `BookishInterchangeCodec` (`RecordLinkEncoding`, `InvalidShorthandHandling`), `SeriesCleaner.Book`, `PublisherCleaner.Book`, `SeriesDetector.Result` and `Captured`, and `NavigateToRecordCommand.Mode`. The organisation rule puts them in a trailing extension.
- Declarations are missing doc comments mainly in `Imp/` (for example the `BookishImportChoice`, `BookishImportMatch` and `BookishImportPlan` members, and `KindleLibraryImporter`), `Cl/`, the service `API` protocol members in `BookishNavigationService` and `BookishRecognitionService`, and the `State` properties of `BookishNavigationService`.

### 🟡 S5: Language, DRY and simplification
- **Repeated service forwarding:** services repeat each `State` property as a get/set forwarder (`BookishNavigationService` has 7, `BookishRecognitionService` 6, `BookishLookupWorkflowService` 9), and `BookishNavigationService.State` re-declares the service's computed index helpers (`App/Services/BookishNavigationService.swift:14-44, 497-506`). Read and write `state` directly in the service, and keep each derived value in one place.
- **Duplicated code:** the NSNumber-to-value conversion is duplicated (C5). `label(for:)` key humanisation is duplicated (`RV/BookishMutationPresentation.swift:83-87`, `RV/BookishRecordPresentation.swift:149-158`), and it uses `replacingOccurrences` where the skill prefers `replacing`. The ID-to-filename encoding is duplicated in both JSON stores. The person/organisation/series kind list is repeated three times (`Imp/BookishImportReconciler.swift`, `Imp/BookishImportPlan.swift`).
- **Unused code:** `DeliciousLibraryImporter.importRecords(from:)` (the synchronous API, used only by tests) duplicates the streaming path's graph building. `BookishRecordID.also(_:)`, `SeriesCleaner.bookIndexPatterns` and `RecordService.records(kind:)` are unused.
- **Hand-written Codable that the compiler would generate:** `RecordSortDirection` (a plain `String` raw-value enum), and `BookishCodingError.==`.
- **Formatting:** `KindleLibraryImporter` creates a `DateFormatter` per book (`Imp/KindleLibraryImporter.swift:185-192`); use `Date(purchaseDate, strategy: .iso8601)`. `String(format: "%02x")` for SHA-256 hex (`:254`) is C-style formatting.
- **Regex compilation:** `SeriesCleaner` compiles `partPattern` on every call, and `SubtitleBookDetector.pattern` is a computed property that compiles a regex on every `detect` (`Cl/SeriesCleaner.swift:52-53`, `Cl/SeriesDetector.swift:212-215`). `DeliciousLibraryImporter.clean` creates new cleaners per book (`Imp/DeliciousLibraryImporter.swift:140-142`). That is roughly ten regex compilations per book. Make them `static let`, or use Swift `Regex` literals, and make the cleaners `Sendable` structs created once.
- **Crashes on bad configuration:** `fatalError` if no provider is supported (`App/Services/BookishRecognitionService.swift:198`, `BookishLookupWorkflowService.swift:96`), and in `BookRecognitionProviderRegistry.recognitionProvider(for:)`. The bundled Fake provider prevents this today, but a configuration change could crash the app. Prefer an "unavailable" state.
- **Security:** `KindleMetadata.decode` turns off `requiresSecureCoding` to unarchive a user-selected database blob (`Imp/KindleLibraryImporter.swift:144-151`). Insecure unarchiving of untrusted data is a known risk. Adopt `NSSecureCoding` for the shim class and use `unarchivedObject(ofClasses:from:)` with an explicit allow-list.
- **Stringly-typed identifiers:** record kinds and keys are string constants (`BookishRecordKind`, `BookishRecordKey`). That's deliberate for a schema-less model ([Decision 0003](../Decisions/0003-schema-less-record-graph.md)), but a `struct RecordKind: RawRepresentable, Hashable, ExpressibleByStringLiteral` would catch mix-ups between kinds and keys at compile time without closing the schema.

### 🟡 S6: Logging
There are no `print` calls, which is good, but hardly any logging either. Only `BookishCleanup` defines a channel, and it has a reverse-DNS name (`Cl/SeriesDetector.swift:10`), against the natural-language convention.
Services, imports, lookup, recognition and the datastore have no diagnostic channels. Add one channel per subsystem ("Datastore", "Import", "Lookup", "Recognition", "Navigation").

---

## 7. Localisation and accessibility

### 🟠 L1: No string catalogues
No module has a `Localizable.xcstrings`, although [Project Layout](Project%20Layout.md#localisation) calls for module-owned catalogues and command names keyed by command ID.
User-facing text is built as `String` in many places, where SwiftUI shows it verbatim:

- command names and help;
- `errorDescription`s;
- status messages ("Imported \(count) … records");
- `BookishMainSection.title`, `BookishFeatureMode.label` and `BookishNewRecordType.menuName`;
- provider labels and descriptions;
- presentation labels ("Yes"/"No", "Default", "Item \(n)").

Plurals are hand-built (`count == 1 ? "record" : "records"`).

**Fix:** add catalogues per module. Use `LocalizedStringResource` (with `bundle: #bundle`) for text that passes through non-view code, and inflection or catalogue plurals for counts. This is a large but mechanical change; it's easier to do before more text is written.

### 🟡 L2: Accessibility
Most of this is good: combined row accessibility, decorative thumbnails hidden, `@ScaledMetric` sizes.
Remaining points are in U2 (the unlabelled lookup field, and the hidden check marks VoiceOver still reads). Also, the capture candidate `Toggle` rows repeat confidence both as visible text and as an accessibility label; check it isn't read twice.

---

## 8. Tests

Test coverage is good (about 5,200 lines, all Swift Testing, network mocked with `URLProtocol`, isolated settings suites, temporary directories). Gaps:

- **🟠 Missing tests for the findings above:** concurrent mutations on one record (A1); rebuild after deleting a sample record (C1); query-result growth when filtering and visiting query sections (P1); recognition results after the image changes (C3); ID collisions in the Delicious fallback (C4).
- **🟡** There are 38 negated `#expect(!…)` checks. The testing skill asks for `== false` so failures show the value (for example `Dependencies/BookishApp/Tests/BookishAppTests/BookishAppImportTests.swift:32, 169`).
- **🟡** There are no UI tests. The standards ask for XCTest UI tests of key flows: import and review, create, filter, and navigating links.
- **🟡** `StarWarsView` has tests but isn't built by the app (S2).

---

## 9. Documentation

- **🟡** [Datastore Implementation](Datastore%20Implementation.md) still describes the "proof of concept" and a `DatastorePrototypeApp` target, and its storage defaults disagree with `AGENTS.md` (S2). Update it to the current JSON implementation and the chosen next step.
- **🟡** [Application Services](Application%20Services.md) and [Command and Environment Design](Command%20and%20Environment%20Design.md) match the code. Once U1 is decided, the view-rules section should say how text-field bindings for commands are handled.
- **🟡** Package READMEs exist for some packages only. `BookishRecordView`, `BookishLookup`, `BookishRecognition` and `BookishCoding` would benefit from a short purpose and API summary, as `StarWarsView` has.

---

## 10. Suggested order of work

1. **Data integrity:** serialise mutation application and add a batch API (A1, A2). Move seeding onto mutations, or record the seed-layer decision (C1). Add the tests from §8.
2. **Stop the unbounded growth (P1):** release unobserved results, and don't cache a result per filter string or host. This is a small change that makes most other performance costs bounded.
3. **Get imports off the main actor (A3):** read the file inside the importer, index the reconciler, and detect catalogue changes with a revision.
4. **Cheaper presentation (P3, P4, P5):** decode once, stop building resolvers per row, remove `AnyView`, cache resolved presentations in `BookishPresentationService.State`, and take `revision` out of query sections (P2).
5. **Bindings and accessibility (U1, U2):** view-local filter text with a debounced command, `Picker`s for provider choice, and a labelled lookup field.
6. **Toolchain alignment (S1):** tools version, targets, per-package concurrency settings, and `@concurrent` on CPU-bound work (A5).
7. **Localisation (L1),** then the hygiene items in S3–S6 and §9.

The deferred [fine-grained record observation](../Journal/2026-09-25-fine-grained-record-observation.md) work replaces the interim fixes in steps 2 and 4. Steps 1, 3, 5 and 6 are needed whichever observation design is chosen.
