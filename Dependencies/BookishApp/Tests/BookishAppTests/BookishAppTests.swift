import BookishCoding
import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import Foundation
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
    let harness = makeUIState(directoryURL: directory)

    await harness.load()

    #expect(harness.statusService.message == "Ready")
    #expect(
      try await harness.storageService.record(id: bookID)?.string("name") == "Recovered")
  }

  @MainActor
  @Test
  func statusServiceStartsInLoadingState() {
    let harness = makeUIState()

    #expect(harness.statusService.message == "Loading")
    #expect(harness.navigation.recordIDs.isEmpty)
  }

  @MainActor
  @Test
  func statusServiceReportsProgressAndErrors() {
    let statusService = BookishStatusService()
    let progress = BookishImportProgress(message: "Importing", completed: 2, total: 4)

    statusService.report(progress: progress)

    #expect(statusService.message == "Importing")
    #expect(statusService.importProgress == progress)

    statusService.clearImportProgress()
    statusService.report(error: BookishStorageError.notLoaded)

    #expect(statusService.importProgress == nil)
    #expect(statusService.message == BookishStorageError.notLoaded.localizedDescription)
  }

  @MainActor
  @Test

  func harnessSeedsImporterCompatibleBookAndPersonRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let authorID = BookishRecordID("seed-author")
    let seededBook = try await harness.storageService.record(id: BookishRecordID("seed-book"))
    let seededAuthor = try await harness.storageService.record(id: authorID)
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

    let presentations = try await harness.presentation.presentations(for: BookishRecordKind.person)
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
    let harness = try makeHarness()
    await harness.load()

    let names = harness.navigation.recordIndexes.map { $0.name }
    let allRecordsIndex = try #require(harness.navigation.recordIndexes.first)
    let storedAllRecordsIndex = try await harness.storageService.record(id: allRecordsIndex.id)
    let storedIndexesIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-indexes"))
    let storedBooksIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-books"))
    let storedSeriesIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-series"))
    let storedMetadataIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-metadata"))
    let storedPresentationsIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-presentations"))
    let seedMarker = try await harness.storageService.record(
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
    #expect(harness.defaultShowsDebugIndexes)
    #expect(harness.navigation.selectedRecordIndexName == "All Records")
    #expect(harness.navigation.selectedRecordIDs.isEmpty == false)
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
    #expect(harness.defaultShowsDebugIndexes == false)
    #expect(harness.navigation.selectedRecordIndexName == "Books")
  }

  @MainActor
  @Test
  func harnessUpdatesVisibleIndexesWhenDeveloperModeChanges() async throws {
    let harness = try makeHarness(defaultShowsDebugIndexes: false)
    await harness.load()

    await harness.setShowsDebugIndexes(true)

    #expect(harness.showsDebugIndexes)
    #expect(harness.navigation.recordIndexes.map(\.name).contains("All Records"))

    await harness.setShowsDebugIndexes(false)

    #expect(harness.showsDebugIndexes == false)
    #expect(harness.navigation.recordIndexes.map(\.name).contains("All Records") == false)
    #expect(harness.navigation.selectedRecordIndexName == "Books")
  }

  @MainActor
  @Test

  func harnessSeedsStandardLayouts() async throws {
    let harness = try makeHarness()
    await harness.load()

    let layoutIDs = Set(harness.presentation.layoutIDs)
    let allFields = try await harness.storageService.record(
      id: BookishRecordID("datastore-all-fields-layout"))
    let book = try await harness.storageService.record(id: BookishRecordID("datastore-book-layout"))
    let bookRelationships = try await harness.storageService.record(
      id: BookishRecordID("datastore-book-relationships-layout"))
    let seedBook = try #require(
      try await harness.storageService.record(id: BookishRecordID("seed-book")))
    let presentedBookLayout = try await harness.presentation.layout(
      for: seedBook,
      recordIndex: harness.navigation.selectedRecordIndex
    )
    let layout = try await harness.storageService.record(
      id: BookishRecordID("datastore-layout-layout"))
    let index = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-layout"))
    let seedMarker = try await harness.storageService.record(
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
    #expect(layoutIDs.contains(BookishRecordID("datastore-book-relationships-layout")) == false)
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
      try await harness.storageService.record(id: BookishRecordID("datastore-person-layout")))
    let section = try #require(
      try await harness.storageService.record(id: BookishRecordID("query-section-person-books")))
    let host = try #require(
      try await harness.storageService.record(id: BookishRecordID("seed-author")))
    let template = try #require(
      section.encoded(BookishRecordKey.query, as: RecordQueryTemplate.self))
    let result = try await harness.storageService.recordQueryResult(for: template, host: host)

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
      try await harness.storageService.record(id: BookishRecordID("seed-author")))
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

    let storedBookIndex = try await harness.storageService.record(
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
    let initialHarness = makeUIState(directoryURL: directory)
    await initialHarness.load()

    let datastore = try await BookishDatastore(directoryURL: directory)
    var bookLayout = try #require(
      await datastore.recordService.record(id: BookishRecordID("datastore-book-layout")))
    bookLayout.properties[BookishRecordKey.name] = .string("My Book Layout")
    try await datastore.recordStore.upsert(bookLayout)

    let subsequentHarness = makeUIState(directoryURL: directory)
    await subsequentHarness.load()

    let storedBookLayout = try await subsequentHarness.storageService.record(
      id: BookishRecordID("datastore-book-layout"))
    let sampleBook = try await subsequentHarness.storageService.record(
      id: BookishRecordID("seed-book"))
    let seedMarker = try await subsequentHarness.storageService.record(
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
    let harness = makeUIState(directoryURL: directory)

    await harness.load()

    let names = harness.navigation.recordIndexes.map(\.name)
    let staleRecordIndex = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-records"))
    let staleRecordIndexKind = try await harness.storageService.record(
      id: BookishRecordID("datastore-index-record-indexes"))
    let staleLayout = try await harness.storageService.record(
      id: BookishRecordID("datastore-book-compact-layout"))
    let relationshipLayout = try await harness.storageService.record(
      id: BookishRecordID("datastore-relationship-layout"))
    let relationshipsIndex = try await harness.storageService.record(
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
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    #expect(commander.availability(ExportInterchangeCommand()) == .disabled)
  }

  @MainActor
  @Test

  func localDatastoreDirectoryUsesInjectedDirectory() throws {
    let directory = try temporaryDirectory()
    let harness = makeUIState(directoryURL: directory)

    #expect(try harness.storageService.localDatastoreDirectory() == directory)
    #expect(FileManager.default.fileExists(atPath: directory.path()))
  }

  @MainActor
  @Test

  func revealDatastoreFolderCommandIsAvailableOnMac() {
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    #expect(commander.availability(RevealDatastoreFolderCommand()) == .enabled)
  }

  @MainActor
  @Test

  func otherDeliciousLibraryImportCommandRequestsViewOwnedFilePicker() async throws {
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    try await commander.perform(ImportOtherDeliciousLibraryCommand())

    #expect(harness.isImportingDeliciousLibrary)
  }

  @MainActor
  @Test

  func deliciousLibrarySmallSampleCommandImportsBundledSample() async throws {
    let harness = try makeHarness()
    let commander = makeCommandCentre(for: harness)
    await harness.load()

    try await commander.perform(ImportDeliciousLibrarySampleCommand(sample: .small))

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(importedBooks.isEmpty == false)
  }

  @MainActor
  @Test

  func deliciousLibrarySampleCommandUsesMenuLabels() {
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .small).name(centre: commander) == "Small Sample")
    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .full).name(centre: commander) == "Full Sample")
  }

  @MainActor
  @Test

  func testErrorCommandIsShownInStatusBar() async {
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    await commander.performWithoutWaiting(ThrowTestErrorCommand()).value

    #expect(harness.statusService.message == "This is a test command error.")
  }

  @MainActor
  @Test
  func commandCentreVendsTheHarnessCapabilitiesAndNavigationService() {
    let navigation = BookishNavigationService()
    let harness = makeUIState(navigation: navigation)
    let commander = makeCommandCentre(for: harness)

    commander.importPresentation.requestInterchangeImport()
    commander.statusService.report(message: "Reported through status capability")

    #expect(harness.isImportingInterchange)
    #expect(harness.statusService.message == "Reported through status capability")
    #expect(commander.datastoreMaintenanceService.hasExportableRecords == false)
    #expect(commander.recordActionService.hasSelectedRecord == false)
    #expect(commander.navigationService.canSelectAnotherRecordIndex == false)
    #expect(commander.navigationService.canSelectAnotherRecord == false)
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
  func engineLoadsStorageAndRefreshesUIState() async throws {
    let engine = BookishEngine(directoryURL: try temporaryDirectory())

    await engine.load()

    #expect(engine.statusService.message == "Ready")
    #expect(engine.navigation.recordIndexIDs.isEmpty == false)
    #expect(engine.uiState.revision == 1)
  }

  @MainActor
  @Test

  func engineOwnsAndInjectsBookishServices() {
    let engine = BookishEngine()

    #expect(engine.uiState.navigation === engine.navigation)
    #expect(engine.uiState.presentation === engine.presentationService)
    #expect(engine.uiState.statusService === engine.statusService)
    #expect(engine.storageService === engine.navigation.storageService)
  }

  @MainActor
  func makeHarness(defaultShowsDebugIndexes: Bool = true) throws -> BookishUIStateService {
    makeUIState(
      directoryURL: try temporaryDirectory(),
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
  }

  @MainActor
  func makeUIState(
    directoryURL: URL? = nil,
    navigation: BookishNavigationService? = nil,
    defaultShowsDebugIndexes: Bool = false
  ) -> BookishUIStateService {
    let storageService =
      navigation?.storageService ?? BookishStorageService(directoryURL: directoryURL)
    storageService.configure(directoryURL: directoryURL)
    let navigation = navigation ?? BookishNavigationService(storageService: storageService)
    let presentationService = BookishPresentationService(storageService: storageService)
    let statusService = BookishStatusService()
    let importingService = BookishImportingService(storageService: storageService)
    let exportingService = BookishExportingService(storageService: storageService)
    return BookishUIStateService(
      navigation: navigation,
      presentation: presentationService,
      statusService: statusService,
      importingService: importingService,
      exportingService: exportingService,
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
  }

  @MainActor
  func makeCommandCentre(for uiState: BookishUIStateService) -> BookishCommandCentre {
    BookishCommandCentre(
      statusService: uiState.statusService,
      importPresentation: uiState,
      datastoreMaintenanceService: uiState,
      storageService: uiState.storageService,
      recordActionService: BookishRecordActionsService(
        storage: uiState.storageService,
        state: uiState,
        statusService: uiState.statusService
      ),
      navigationService: uiState.navigation
    )
  }

  @MainActor
  func records(for harness: BookishUIStateService) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.recordIDs {
      if let record = try await harness.storageService.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  @MainActor
  func selectedRecords(for harness: BookishUIStateService) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.selectedRecordIDs {
      if let record = try await harness.storageService.record(id: id) {
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

@MainActor
extension BookishUIStateService {
  /// The storage service used to set up and inspect UI-state integration tests.
  var storageService: BookishStorageService {
    navigation.storageService
  }

  /// Loads test storage and synchronises its browser-facing UI state.
  func load() async {
    do {
      try await storageService.load()
      try await refreshBrowser()
      statusService.report(message: "Ready")
    } catch {
      statusService.report(error: error)
    }
  }
}
