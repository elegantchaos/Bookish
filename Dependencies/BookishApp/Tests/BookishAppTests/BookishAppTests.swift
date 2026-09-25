import BookishCoding
import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import Foundation
import Observation
import Testing

@testable import BookishApp

struct BookishAppTests {
  @MainActor
  @Test
  func startupRebuildsAnUnreadableRecordStoreFromMutations() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    let bookID = BookishRecordID("recovered-book")
    try await datastore.mutationService.perform(
      .setProperty(recordID: bookID, kind: "book", key: "name", value: .string("Recovered")))
    let recordsDirectory = directory.appending(path: "records", directoryHint: .isDirectory)
    try Data("not valid record JSON".utf8).write(
      to: recordsDirectory.appending(path: "record-old.json"))
    let harness = makeEngine(directoryURL: directory)

    await harness.load()

    #expect(harness.status.state.message == "Ready")
    #expect(
      try await harness.storage.record(id: bookID)?.string("name") == "Recovered")
  }

  @MainActor
  @Test
  func statusServiceStartsInLoadingState() {
    let statusService = BookishStatusService()

    #expect(statusService.state.message == "Loading")
  }

  @MainActor
  @Test
  func statusServiceReportsProgressAndErrors() {
    let statusService = BookishStatusService()
    let state = statusService.state
    let progress = BookishImportProgress(message: "Importing", completed: 2, total: 4)

    statusService.report(progress: progress)

    #expect(statusService.state === state)
    #expect(state.message == "Importing")
    #expect(state.importProgress == progress)

    statusService.clearImportProgress()
    state.report(error: BookishStorageError.notLoaded)

    #expect(state.importProgress == nil)
    #expect(state.message == BookishStorageError.notLoaded.localizedDescription)

    statusService.report(message: "Ready")
    #expect(state.message == "Ready")
  }

  @MainActor
  @Test

  func harnessSeedsImporterCompatibleBookAndPersonRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let authorID = BookishRecordID("seed-author")
    let seededBook = try await harness.storage.record(id: BookishRecordID("seed-book"))
    let seededAuthor = try await harness.storage.record(id: authorID)
    let book = try #require(seededBook)
    let author = try #require(seededAuthor)

    #expect(book.kind == BookishRecordKind.book)
    #expect(book.string(BookishRecordKey.name) == "The Left Hand of Darkness")
    #expect(book.list(BookishRecordKey.authors) == [.record(authorID)])
    #expect(author.kind == BookishRecordKind.person)
    #expect(author.string(BookishRecordKey.name) == "Ursula K. Le Guin")
    #expect(book.string(BookishRecordKey.source) == author.string(BookishRecordKey.source))
  }

  @MainActor
  @Test
  func presentationServiceUsesSpecificBookPresentationForBookFields() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let presentationService = BookishPresentationService(storageService: storage)

    let presentations = try await presentationService.presentations(for: BookishRecordKind.book)
    let presentation = try #require(presentations.first)

    #expect(presentation.id == BookishRecordID("presentation.type.book"))
    #expect(
      presentation.encoded(BookishRecordKey.name, as: BookishPropertyPresentation.self)?.icon
        == "textformat")
    #expect(
      presentation.encoded(BookishRecordKey.name, as: BookishPropertyPresentation.self)?.label
        == "Title")
    #expect(
      presentation.encoded(BookishRecordKey.originalData, as: BookishPropertyPresentation.self)?
        .label == "Original Data")
    #expect(presentations.last?.id == BookishRecordID("presentation.type.*"))

    for (key, label) in [
      (BookishRecordKey.subtitle, "Subtitle"),
      (BookishRecordKey.authors, "Authors"),
      (BookishRecordKey.illustrators, "Illustrators"),
      (BookishRecordKey.series, "Series"),
      (BookishRecordKey.seriesPosition, "Series Number"),
      (BookishRecordKey.publishers, "Publishers"),
      (BookishRecordKey.publishedDate, "Published"),
      (BookishRecordKey.format, "Format"),
      (BookishRecordKey.pages, "Pages"),
      (BookishRecordKey.isbn, "ISBN"),
      (BookishRecordKey.asin, "ASIN"),
      (BookishRecordKey.dewey, "Dewey Decimal"),
      (BookishRecordKey.genres, "Genres"),
      (BookishRecordKey.editions, "Editions"),
      (BookishRecordKey.height, "Height"),
      (BookishRecordKey.width, "Width"),
      (BookishRecordKey.length, "Length"),
      (BookishRecordKey.addedDate, "Date Added"),
      (BookishRecordKey.modifiedDate, "Date Modified"),
      (BookishRecordKey.imageURLs, "Cover Images"),
      (BookishRecordKey.originalData, "Original Data"),
    ] {
      #expect(
        presentation.encoded(key, as: BookishPropertyPresentation.self)?.label == label)
      #expect(presentation.encoded(key, as: BookishPropertyPresentation.self)?.icon != nil)
    }
    #expect(
      presentation.encoded(BookishRecordKey.length, as: BookishPropertyPresentation.self)?.icon
        == "ruler")
  }

  @MainActor
  @Test
  func fallbackPresentationCoversSharedSeedProperties() async throws {
    let harness = try makeHarness()
    await harness.load()

    let presentations = try await harness.presentation.presentations(
      for: BookishRecordKind.person)
    let presentation = try #require(presentations.first)

    for key in [
      BookishRecordKey.name,
      BookishRecordKey.source,
      BookishRecordKey.importedID,
      BookishRecordKey.note,
      BookishRecordKey.status,
      BookishRecordKey.items,
      BookishRecordKey.debugOnly,
      BookishRecordKey.position,
      BookishRecordKey.layout,
      BookishRecordKey.types,
      BookishRecordKey.query,
      BookishRecordKey.fields,
      BookishRecordKey.excludedFields,
      BookishRecordKey.presentation,
    ] {
      #expect(presentation.encoded(key, as: BookishPropertyPresentation.self)?.label != nil)
    }
  }

  @MainActor
  @Test
  func harnessSeedsRecordKindMetadata() async throws {
    let harness = try makeHarness()
    await harness.load()

    let bookMetadata = try #require(
      try await harness.presentation.recordKindMetadata(for: BookishRecordKind.book))
    let unknownMetadata = try #require(
      try await harness.presentation.recordKindMetadata(for: "customKind"))

    #expect(bookMetadata.kind == BookishRecordKind.metadata)
    #expect(bookMetadata.string(BookishRecordKey.name) == "Book")
    #expect(bookMetadata.string(BookishRecordKey.icon) == "books.vertical")
    #expect(bookMetadata.strings(BookishRecordKey.types) == [BookishRecordKind.book])
    #expect(
      bookMetadata.record(BookishRecordKey.presentation)
        == BookishRecordID("presentation.type.book"))
    #expect(unknownMetadata.id == BookishRecordID("metadata.type.*"))
  }

  @MainActor
  @Test

  func harnessSeedsBrowserIndexRecords() async throws {
    let settingsName = "BookishAppBrowserIndexTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: settingsName))
    defer { settings.removePersistentDomain(forName: settingsName) }
    let directoryURL = try temporaryDirectory()
    let harness = makeEngine(
      directoryURL: directoryURL, settings: settings, defaultShowsDebugIndexes: true)
    await harness.load()

    let names = harness.navigation.recordIndexes.map { $0.name }
    let allRecordsIndex = try #require(harness.navigation.recordIndexes.first)
    let storedAllRecordsIndex = try await harness.storage.record(id: allRecordsIndex.id)
    let storedIndexesIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-indexes"))
    let storedBooksIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-books"))
    let storedSeriesIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-series"))
    let storedMetadataIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-metadata"))
    let storedPresentationsIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-presentations"))
    let seedMarker = try await harness.storage.record(
      id: BookishRecordID("datastore-seed-marker"))

    #expect(
      names == [
        "All Records",
        "Books",
        "People",
        "Organisations",
        "Series",
        "Lists",
        "Layouts",
        "Indexes",
        "Metadata",
        "Presentations",
      ])
    #expect(storedAllRecordsIndex?.kind == BookishRecordKind.index)
    #expect(storedAllRecordsIndex?.bool(BookishRecordKey.debugOnly) == true)
    #expect(
      storedAllRecordsIndex?.record(BookishRecordKey.layout)
        == BookishRecordID("datastore-all-fields-layout"))
    #expect(storedAllRecordsIndex?.strings(BookishRecordKey.types) == [BookishRecordKey.allTypes])
    #expect(allRecordsIndex.icon == "square.grid.2x2")
    #expect(storedSeriesIndex?.string(BookishRecordKey.icon) == "square.stack.3d.up")
    #expect(storedIndexesIndex?.kind == BookishRecordKind.index)
    #expect(storedIndexesIndex?.string(BookishRecordKey.name) == "Indexes")
    #expect(
      BookishRecordIndex(record: try #require(storedIndexesIndex)).icon == "list.bullet.rectangle")
    #expect(storedIndexesIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.index])
    #expect(storedIndexesIndex?.bool(BookishRecordKey.debugOnly) == true)
    #expect(storedMetadataIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.metadata])
    #expect(storedMetadataIndex?.bool(BookishRecordKey.debugOnly) == true)
    #expect(
      storedMetadataIndex?.record(BookishRecordKey.layout)
        == BookishRecordID("datastore-all-fields-layout"))
    #expect(
      storedPresentationsIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.presentation])
    #expect(storedPresentationsIndex?.bool(BookishRecordKey.debugOnly) == true)
    #expect(storedBooksIndex?.bool(BookishRecordKey.debugOnly) == false)
    #expect(storedBooksIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.book])
    #expect(seedMarker?.kind == BookishRecordKind.seedMarker)
    #expect(harness.browser.defaultShowsDebugIndexes)
    #expect(harness.navigation.selectedRecordIndexName == "All Records")
    #expect(!harness.navigation.selectedRecordIDs.isEmpty)
  }

  @MainActor
  @Test
  func newRecordUsesConfiguredIndexAndSelectsCreatedRecord() async throws {
    let harness = try makeHarness(defaultShowsDebugIndexes: false)
    await harness.load()
    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-people"))
    try await harness.navigation.setRecordNameFilter("hidden")

    try await harness.recordCreation.create(.book)

    #expect(harness.navigation.selectedRecordIndexID == BookishRecordID("datastore-index-books"))
    #expect(harness.navigation.recordNameFilter.isEmpty)
    let selectedID = try #require(harness.navigation.selectedRecordID)
    #expect(harness.navigation.selectedRecordIDs.contains(selectedID))
    let record = try #require(try await harness.storage.record(id: selectedID))
    #expect(record.kind == BookishRecordKind.book)
    #expect(record.string(BookishRecordKey.name) == "New Book")
  }

  @MainActor
  @Test
  func newRecordSkipsAnIndexWhoseQueryWouldHideIt() async throws {
    let harness = try makeHarness(defaultShowsDebugIndexes: false)
    await harness.load()
    let readingIndexID = BookishRecordID("reading-books")
    let readingIndex = try BookishRecordIndex.record(
      id: readingIndexID,
      name: "Reading",
      position: 0,
      query: RecordQuery(
        predicate: .and([
          .kind(BookishRecordKind.book),
          .property(BookishRecordKey.status, equals: .string("Reading")),
        ])),
      newRecordTypes: [.book]
    )
    try await harness.storage.upsert(records: [readingIndex])
    try await harness.browser.refresh()
    try await harness.navigation.select(recordIndexID: readingIndexID)

    try await harness.recordCreation.create(.book)

    #expect(harness.navigation.selectedRecordIndexID == BookishRecordID("datastore-index-books"))
    #expect(harness.navigation.selectedRecordID != nil)
  }

  @MainActor
  @Test
  func existingLibraryIndexesGainCreationMetadataWithoutReplacingTheIndex() async throws {
    let directory = try temporaryDirectory()
    let first = makeEngine(directoryURL: directory)
    await first.load()
    let indexID = BookishRecordID("datastore-index-books")
    try await first.storage.perform(
      MutationRecord(
        operation: .deleteProperty(
          recordID: indexID, key: BookishRecordKey.newRecordTypes))
    )
    try await first.storage.perform(
      MutationRecord(
        operation: .setProperty(
          recordID: indexID, kind: BookishRecordKind.index,
          key: BookishRecordKey.name, value: .string("My Books")))
    )

    let reopened = makeEngine(directoryURL: directory)
    await reopened.load()
    let stored = try #require(try await reopened.storage.record(id: indexID))

    #expect(stored.string(BookishRecordKey.name) == "My Books")
    #expect(stored.strings(BookishRecordKey.newRecordTypes) == [BookishRecordKind.book])
  }

  @MainActor
  @Test

  func harnessHidesDebugIndexesWhenDebugIndexesAreDisabled() async throws {
    let harness = try makeHarness(defaultShowsDebugIndexes: false)
    await harness.load()

    #expect(
      harness.navigation.recordIndexes.map(\.name) == [
        "Books",
        "People",
        "Organisations",
        "Series",
        "Lists",
      ])
    #expect(!harness.browser.defaultShowsDebugIndexes)
    #expect(harness.navigation.selectedRecordIndexName == "Books")
  }

  @MainActor
  @Test
  func harnessUpdatesVisibleIndexesWhenDeveloperModeChanges() async throws {
    let harness = try makeHarness(defaultShowsDebugIndexes: false)
    await harness.load()

    await harness.browser.setShowsDebugIndexes(true)

    #expect(harness.browser.showsDebugIndexes)
    #expect(harness.navigation.recordIndexes.map(\.name).contains("All Records"))

    await harness.browser.setShowsDebugIndexes(false)

    #expect(!harness.browser.showsDebugIndexes)
    #expect(!harness.navigation.recordIndexes.map(\.name).contains("All Records"))
    #expect(harness.navigation.selectedRecordIndexName == "Books")
  }

  @MainActor
  @Test

  func harnessSeedsStandardLayouts() async throws {
    let harness = try makeHarness()
    await harness.load()

    let layoutIDs = Set(harness.presentation.layoutIDs)
    let allFields = try await harness.storage.record(
      id: BookishRecordID("datastore-all-fields-layout"))
    let book = try await harness.storage.record(id: BookishRecordID("datastore-book-layout"))
    let bookRelationships = try await harness.storage.record(
      id: BookishRecordID("datastore-book-relationships-layout"))
    let seedBook = try #require(
      try await harness.storage.record(id: BookishRecordID("seed-book")))
    let presentedBookLayout = try await harness.presentation.layout(
      for: seedBook,
      recordIndex: harness.navigation.selectedRecordIndex
    )
    let layout = try await harness.storage.record(
      id: BookishRecordID("datastore-layout-layout"))
    let index = try await harness.storage.record(
      id: BookishRecordID("datastore-index-layout"))
    let seedMarker = try await harness.storage.record(
      id: BookishRecordID("datastore-seed-marker"))

    #expect(layoutIDs.contains(BookishRecordID("datastore-book-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-person-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-organisation-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-series-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-list-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-layout-layout")))
    #expect(layoutIDs.contains(BookishRecordID("datastore-index-layout")))
    #expect(allFields?.list(BookishRecordKey.fields) == [.string(BookishRecordKey.allOtherFields)])
    #expect(allFields?.strings(BookishRecordKey.types) == [BookishRecordKey.allTypes])
    #expect(book?.string(BookishRecordKey.name) == "Book")
    #expect(book?.strings(BookishRecordKey.types) == [BookishRecordKind.book])
    #expect(
      book?.list(BookishRecordKey.fields)?.contains(
        .record(BookishRecordID("datastore-book-identifiers-layout")))
        == true)
    #expect(bookRelationships?.bool(BookishRecordKey.isSection) == true)
    #expect(bookRelationships?.strings(BookishRecordKey.types) == [BookishRecordKind.book])
    #expect(
      bookRelationships?.list(BookishRecordKey.fields) == [
        .string(BookishRecordKey.authors), .string(BookishRecordKey.illustrators),
        .string(BookishRecordKey.series), .string(BookishRecordKey.seriesPosition),
        .string(BookishRecordKey.publishers),
      ])
    #expect(!layoutIDs.contains(BookishRecordID("datastore-book-relationships-layout")))
    #expect(presentedBookLayout?.id == BookishRecordID("datastore-book-layout"))
    #expect(
      layout?.list(BookishRecordKey.fields)?.contains(.string(BookishRecordKey.source)) == false)
    #expect(index?.strings(BookishRecordKey.types) == [BookishRecordKind.index])
    #expect(
      index?.list(BookishRecordKey.fields)?.contains(.string(BookishRecordKey.debugOnly)) == true)
    #expect(
      index?.list(BookishRecordKey.fields)?.contains(.string(BookishRecordKey.source)) == false)
    #expect(seedMarker?.string(BookishRecordKey.source) == nil)
  }

  @MainActor
  @Test
  func harnessSeedsHostBoundQuerySections() async throws {
    let harness = try makeHarness()
    await harness.load()

    let personLayout = try #require(
      try await harness.storage.record(id: BookishRecordID("datastore-person-layout")))
    let section = try #require(
      try await harness.storage.record(id: BookishRecordID("query-section-person-books")))
    let host = try #require(
      try await harness.storage.record(id: BookishRecordID("seed-author")))
    let template = try #require(
      section.encoded(BookishRecordKey.query, as: RecordQueryTemplate.self))
    let result = try await harness.storage.recordQueryResult(for: template, host: host)

    #expect(personLayout.kind == BookishRecordKind.layout)
    #expect(
      personLayout.list(BookishRecordKey.fields)?.contains(
        .record(BookishRecordID("query-section-person-books"))) == true)
    #expect(section.kind == BookishRecordKind.querySection)
    #expect(section.string(BookishRecordKey.emptyMessage) == "No linked books.")
    #expect(result.records.map(\.id) == [BookishRecordID("seed-book")])
  }

  @MainActor
  @Test
  func harnessUsesTheRecordKindLayoutForLinkedRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let person = try #require(
      try await harness.storage.record(id: BookishRecordID("seed-author")))
    let layout = try await harness.presentation.layout(
      for: person,
      recordIndex: harness.navigation.selectedRecordIndex
    )

    #expect(layout?.id == BookishRecordID("datastore-person-layout"))
  }

  @MainActor
  @Test

  func layoutChoicesMatchSelectedIndexTypes() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-books"))

    #expect(
      Set(harness.presentation.compatibleLayoutIDs) == [
        BookishRecordID("datastore-all-fields-layout"),
        BookishRecordID("datastore-book-layout"),
      ])

    harness.presentation.selectedLayoutID = BookishRecordID("datastore-book-layout")
    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-people"))

    #expect(harness.presentation.selectedLayoutID == nil)
    #expect(
      Set(harness.presentation.compatibleLayoutIDs) == [
        BookishRecordID("datastore-all-fields-layout"),
        BookishRecordID("datastore-person-layout"),
      ])
  }

  @MainActor
  @Test

  func harnessSeedsDebugBrowserIndexRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let storedBookIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-books"))

    if let encodedQuery = storedBookIndex?.properties[BookishRecordKey.query]?.encodedValue {
      do {
        let query = try encodedQuery.decode(RecordQuery.self)
        #expect(query.predicate == RecordPredicate.kind(BookishRecordKind.book))
      } catch {
        Issue.record("Failed to decode stored book index query: \(error)")
      }
    } else {
      Issue.record("Stored book index query is missing.")
    }
    #expect(storedBookIndex?.kind == BookishRecordKind.index)
    #expect(storedBookIndex?.bool(BookishRecordKey.debugOnly) == false)
    #expect(
      storedBookIndex?.record(BookishRecordKey.layout) == BookishRecordID("datastore-book-layout"))
    #expect(storedBookIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.book])
    #expect(harness.navigation.recordIndexIDs.contains(BookishRecordID("datastore-index-books")))
  }

  @MainActor
  @Test

  func harnessPreservesConfigurationEditsAfterFirstRun() async throws {
    let directory = try temporaryDirectory()
    let initialHarness = makeEngine(directoryURL: directory)
    await initialHarness.load()

    let datastore = try await BookishDatastore(directoryURL: directory)
    var bookLayout = try #require(
      await datastore.recordService.record(id: BookishRecordID("datastore-book-layout")))
    bookLayout.properties[BookishRecordKey.name] = .string("My Book Layout")
    try await datastore.recordStore.upsert(bookLayout)

    let subsequentHarness = makeEngine(directoryURL: directory)
    await subsequentHarness.load()

    let storedBookLayout = try await subsequentHarness.storage.record(
      id: BookishRecordID("datastore-book-layout"))
    let sampleBook = try await subsequentHarness.storage.record(
      id: BookishRecordID("seed-book"))
    let seedMarker = try await subsequentHarness.storage.record(
      id: BookishRecordID("datastore-seed-marker"))

    #expect(storedBookLayout?.string(BookishRecordKey.name) == "My Book Layout")
    #expect(sampleBook?.kind == BookishRecordKind.book)
    #expect(seedMarker?.string(BookishRecordKey.source) == nil)
  }

  @MainActor
  @Test

  func harnessDoesNotPruneConfigurationRecordsAfterFirstRun() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-seed-marker"), kind: BookishRecordKind.seedMarker)
    )
    try await datastore.recordStore.upsert(
      try BookishRecordIndex.record(
        id: BookishRecordID("datastore-index-records"),
        name: "Records",
        position: 1,
        query: RecordQuery(predicate: .kind(BookishRecordKind.record))
      ))
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-index-record-indexes"),
        kind: "recordIndex",
        properties: [
          BookishRecordKey.name: .string("Record Indexes"),
          BookishRecordKey.source: .string("com.elegantchaos.bookish.seed"),
        ]
      ))
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-book-compact-layout"),
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.name: .string("Compact Summary"),
          BookishRecordKey.source: .string("com.elegantchaos.bookish.seed"),
        ]
      ))
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-relationship-layout"),
        kind: BookishRecordKind.layout,
        properties: [BookishRecordKey.name: .string("Relationship")]
      ))
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-index-relationships"),
        kind: BookishRecordKind.index,
        properties: [BookishRecordKey.name: .string("Relationships")]
      ))
    let harness = makeEngine(directoryURL: directory)

    await harness.load()

    let names = harness.navigation.recordIndexes.map(\.name)
    let staleRecordIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-records"))
    let staleRecordIndexKind = try await harness.storage.record(
      id: BookishRecordID("datastore-index-record-indexes"))
    let staleLayout = try await harness.storage.record(
      id: BookishRecordID("datastore-book-compact-layout"))
    let relationshipLayout = try await harness.storage.record(
      id: BookishRecordID("datastore-relationship-layout"))
    let relationshipsIndex = try await harness.storage.record(
      id: BookishRecordID("datastore-index-relationships"))

    #expect(names.contains("Records"))
    #expect(staleRecordIndex != nil)
    #expect(staleRecordIndexKind != nil)
    #expect(staleLayout != nil)
    #expect(relationshipLayout != nil)
    #expect(relationshipsIndex != nil)
  }

  @MainActor
  @Test
  func exportCommandIsDisabledWithoutRecords() {
    let harness = makeEngine()
    let commander = harness

    #expect(commander.availability(ExportInterchangeCommand()) == .disabled)
  }

  @MainActor
  @Test

  func localDatastoreDirectoryUsesInjectedDirectory() throws {
    let directory = try temporaryDirectory()
    let harness = makeEngine(directoryURL: directory)

    #expect(try harness.storage.localDatastoreDirectory() == directory)
    #expect(FileManager.default.fileExists(atPath: directory.path()))
  }

  @MainActor
  @Test

  func revealDatastoreFolderCommandIsAvailableOnlyWithAppKit() {
    let harness = makeEngine()
    let commander = harness

    #if canImport(AppKit)
      #expect(commander.availability(RevealDatastoreFolderCommand()) == .enabled)
    #else
      #expect(commander.availability(RevealDatastoreFolderCommand()) == .disabled)
    #endif
  }

  @MainActor
  @Test

  func otherDeliciousLibraryImportCommandRequestsViewOwnedFilePicker() async throws {
    let harness = makeEngine()
    let commander = harness

    try await commander.perform(ImportOtherDeliciousLibraryCommand())

    #expect(harness.importing.state.isImportingDeliciousLibrary)
    #expect(harness.navigation.selectedMainSection == .importing)
  }

  @MainActor
  @Test
  func kindleLibraryImportCommandRequestsViewOwnedFilePicker() async throws {
    let harness = makeEngine()

    try await harness.perform(ImportKindleLibraryCommand())

    #expect(harness.importing.state.isImportingKindleLibrary)
    #expect(harness.navigation.selectedMainSection == .importing)
  }

  @MainActor
  @Test

  func deliciousLibrarySmallSampleCommandImportsBundledSample() async throws {
    let harness = try makeHarness()
    let commander = harness
    await harness.load()

    try await commander.perform(ImportDeliciousLibrarySampleCommand(sample: .small))
    let plan = try #require(harness.importing.state.pendingImportPlan)
    #expect(harness.navigation.selectedMainSection == .importing)
    let choices = Dictionary(
      uniqueKeysWithValues: plan.reviewEntries.map { entry in
        (entry.id, BookishImportChoice.create)
      })
    await harness.importing.applyPendingImport(choices: choices)

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(!importedBooks.isEmpty)
  }

  @MainActor
  @Test
  func kindleFixtureCommandImportsBundledDatabase() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.perform(ImportKindleLibrarySampleCommand())

    let plan = try #require(harness.importing.state.pendingImportPlan)
    #expect(harness.navigation.selectedMainSection == .importing)
    #expect(
      plan.entries.contains { entry in
        entry.record.kind == BookishRecordKind.book
          && entry.record.string(BookishRecordKey.name) == "The Glass Orbit"
      })
  }

  @MainActor
  @Test

  func deliciousLibrarySampleCommandUsesMenuLabels() {
    let harness = makeEngine()
    let commander = harness

    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .small).name(centre: commander) == "Small Sample")
    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .full).name(centre: commander) == "Full Sample")
  }

  @MainActor
  @Test

  func testErrorCommandIsShownInStatusBar() async {
    let harness = makeEngine()
    let commander = harness

    await commander.performWithoutWaiting(ThrowTestErrorCommand()).value

    #expect(harness.status.state.message == "This is a test command error.")
  }

  @MainActor
  @Test
  func commandCentreVendsTheHarnessCapabilitiesAndNavigationService() {
    let harness = makeEngine()
    let commander = harness

    commander.importingAPI.requestInterchangeImport()
    commander.statusAPI.report(message: "Reported through status capability")

    #expect(harness.importing.state.isImportingInterchange)
    #expect(harness.status.state.message == "Reported through status capability")
    #expect(!commander.exportingAPI.hasExportableRecords)
    #expect(!commander.recordActionsAPI.hasSelectedRecord)
    #expect(!commander.navigationAPI.canSelectAnotherRecordIndex)
    #expect(!commander.navigationAPI.canSelectAnotherRecord)
  }

  @MainActor
  @Test

  func engineUsesApplicationStartupLoop() {
    let engine = BookishEngine()

    guard case .uninitialised = engine.state else {
      Issue.record("Expected engine to start uninitialised.")
      return
    }

    engine.start()

    guard case .starting = engine.state else {
      Issue.record("Expected engine to enter startup.")
      return
    }
    #expect(engine.startupTask != nil)
  }

  @MainActor
  @Test
  func engineLoadsStorageAndRefreshesBrowser() async throws {
    let engine = BookishEngine(directoryURL: try temporaryDirectory())

    await engine.load()

    #expect(engine.status.state.message == "Ready")
    #expect(!engine.navigation.recordIndexIDs.isEmpty)
    #expect(engine.storage.state.revision == 1)
    #expect(
      try await engine.storage.state.record(id: BookishRecordID("seed-book"))?.kind
        == BookishRecordKind.book)
  }

  @MainActor
  @Test

  func engineOwnsAndInjectsBookishServices() {
    let engine = BookishEngine()

    #expect(engine.storage === engine.navigation.storageService)
    #expect(engine.browserAPI === engine.browser)
    #expect(engine.importingAPI === engine.importing)
    #expect(engine.exportingAPI === engine.exporting)
    #expect(engine.settingsPresentationAPI === engine.settingsPresentation)
    #expect(engine.recordCreationAPI === engine.recordCreation)
    #expect(engine.recordActionsAPI === engine.recordActions)
  }

  @MainActor
  @Test
  func newRecordCommandsBecomeEnabledWhenTheEngineLoads() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let changes = ObservedChanges()

    let availability = withObservationTracking {
      engine.availability(NewRecordCommand(type: .book))
    } onChange: {
      changes.record()
    }
    #expect(availability == .disabled)

    await engine.load()

    #expect(changes.count > 0)
    for type in BookishNewRecordType.allCases {
      #expect(engine.availability(NewRecordCommand(type: type)) == .enabled)
    }
  }

  @MainActor
  @Test
  func engineVendsServicesDirectlyToCommands() async {
    let engine = BookishEngine()

    await engine.performWithoutWaiting(ImportInterchangeCommand()).value
    await engine.performWithoutWaiting(ThrowTestErrorCommand()).value

    #expect(engine.importing.state.isImportingInterchange)
    #expect(engine.status.state.message == "This is a test command error.")
  }

  @MainActor
  func makeHarness(defaultShowsDebugIndexes: Bool = true) throws -> BookishEngine {
    makeEngine(
      directoryURL: try temporaryDirectory(),
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
  }

  /// Creates an engine whose settings are isolated from other tests.
  @MainActor
  func makeEngine(
    directoryURL: URL? = nil,
    settings: UserDefaults? = nil,
    defaultShowsDebugIndexes: Bool = false
  ) -> BookishEngine {
    let suiteName = "BookishAppTests-\(UUID().uuidString)"
    guard let settings = settings ?? UserDefaults(suiteName: suiteName) else {
      preconditionFailure("Could not create test settings suite")
    }
    return BookishEngine(
      directoryURL: directoryURL,
      defaultShowsDebugIndexes: defaultShowsDebugIndexes,
      settings: settings
    )
  }

  @MainActor
  func records(for harness: BookishEngine) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.recordIDs {
      if let record = try await harness.storage.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  @MainActor
  func selectedRecords(for harness: BookishEngine) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.selectedRecordIDs {
      if let record = try await harness.storage.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  func temporaryDirectory() throws -> URL {
    let directory = URL.temporaryDirectory.appending(
      path: "BookishAppTests-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  func deliciousSampleURL() throws -> URL {
    try BookishImporterSamples.deliciousLibraryURL(for: .small)
  }

  func browserIndexRecord(
    id: String,
    name: String,
    predicate: RecordPredicate
  ) throws -> BookishRecord {
    try BookishRecordIndex.record(
      id: BookishRecordID(id),
      name: name,
      position: 0,
      query: RecordQuery(predicate: predicate)
    )
  }
}

/// Counts observation change notifications delivered to a test.
final class ObservedChanges: @unchecked Sendable {
  /// The number of notifications received.
  private(set) var count = 0

  /// Records one notification.
  func record() {
    count += 1
  }
}
