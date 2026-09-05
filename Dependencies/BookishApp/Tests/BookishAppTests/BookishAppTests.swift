import BookishCoding
import BookishDatastore
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
    let harness = BookishHarness(directoryURL: directory)

    await harness.load()

    #expect(harness.status == "Ready")
    #expect(
      try await harness.record(id: bookID)?.string("name") == "Recovered")
  }

  @MainActor
  @Test
  func harnessStartsInLoadingState() {
    let harness = BookishHarness()

    #expect(harness.status == "Loading")
    #expect(harness.navigation.recordIDs.isEmpty)
  }

  @MainActor
  @Test

  func harnessSeedsImporterCompatibleBookAndPersonRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let authorID = BookishRecordID("seed-author")
    let seededBook = try await harness.record(id: BookishRecordID("seed-book"))
    let seededAuthor = try await harness.record(id: authorID)
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
  func harnessUsesSpecificBookPresentationForBookFields() async throws {
    let harness = try makeHarness()
    await harness.load()

    let presentations = try await harness.presentations(for: BookishRecordKind.book)
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

    let presentations = try await harness.presentations(for: BookishRecordKind.person)
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

  func harnessSeedsBrowserIndexRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let names = harness.navigation.recordIndexes.map { $0.name }
    let allRecordsIndex = try #require(harness.navigation.recordIndexes.first)
    let storedAllRecordsIndex = try await harness.record(id: allRecordsIndex.id)
    let storedIndexesIndex = try await harness.record(
      id: BookishRecordID("datastore-index-indexes"))
    let storedBooksIndex = try await harness.record(id: BookishRecordID("datastore-index-books"))
    let seedMarker = try await harness.record(id: BookishRecordID("datastore-seed-marker"))

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
      ])
    #expect(storedAllRecordsIndex?.kind == BookishRecordKind.index)
    #expect(storedAllRecordsIndex?.bool(BookishRecordKey.debugOnly) == true)
    #expect(
      storedAllRecordsIndex?.record(BookishRecordKey.layout)
        == BookishRecordID("datastore-all-fields-layout"))
    #expect(storedAllRecordsIndex?.strings(BookishRecordKey.types) == [BookishRecordKey.allTypes])
    #expect(storedIndexesIndex?.kind == BookishRecordKind.index)
    #expect(storedIndexesIndex?.string(BookishRecordKey.name) == "Indexes")
    #expect(storedIndexesIndex?.strings(BookishRecordKey.types) == [BookishRecordKind.index])
    #expect(storedIndexesIndex?.bool(BookishRecordKey.debugOnly) == true)
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

  func harnessSeedsStandardLayouts() async throws {
    let harness = try makeHarness()
    await harness.load()

    let layoutIDs = Set(harness.layoutIDs)
    let allFields = try await harness.record(id: BookishRecordID("datastore-all-fields-layout"))
    let book = try await harness.record(id: BookishRecordID("datastore-book-layout"))
    let layout = try await harness.record(id: BookishRecordID("datastore-layout-layout"))
    let index = try await harness.record(id: BookishRecordID("datastore-index-layout"))
    let seedMarker = try await harness.record(id: BookishRecordID("datastore-seed-marker"))

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
    #expect(book?.list(BookishRecordKey.fields)?.contains(.string(BookishRecordKey.isbn)) == true)
    #expect(
      book?.list(BookishRecordKey.fields)?.contains(.string(BookishRecordKey.allOtherFields))
        == true)
    #expect(
      book?.list(BookishRecordKey.excludedFields) == [.string(BookishRecordKey.originalData)])
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

  func layoutChoicesMatchSelectedIndexTypes() async throws {
    let harness = try makeHarness()
    await harness.load()

    await harness.select(recordIndexID: BookishRecordID("datastore-index-books"))

    #expect(
      Set(harness.compatibleLayoutIDs) == [
        BookishRecordID("datastore-all-fields-layout"),
        BookishRecordID("datastore-book-layout"),
      ])

    harness.selectedLayoutID = BookishRecordID("datastore-book-layout")
    await harness.select(recordIndexID: BookishRecordID("datastore-index-people"))

    #expect(harness.selectedLayoutID == nil)
    #expect(
      Set(harness.compatibleLayoutIDs) == [
        BookishRecordID("datastore-all-fields-layout"),
        BookishRecordID("datastore-person-layout"),
      ])
  }

  @MainActor
  @Test

  func harnessSeedsDebugBrowserIndexRecords() async throws {
    let harness = try makeHarness()
    await harness.load()

    let storedBookIndex = try await harness.record(id: BookishRecordID("datastore-index-books"))

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

  func harnessReimportsPresentationWithoutSampleDataAfterFirstRun() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: BookishRecordID("datastore-seed-marker"),
        kind: BookishRecordKind.seedMarker,
        properties: [BookishRecordKey.source: .string("com.elegantchaos.bookish.seed")]
      )
    )
    let harness = BookishHarness(directoryURL: directory)

    await harness.load()

    let allRecordsIndex = try await harness.record(
      id: BookishRecordID("datastore-index-all-records"))
    let bookLayout = try await harness.record(id: BookishRecordID("datastore-book-layout"))
    let sampleBook = try await harness.record(id: BookishRecordID("seed-book"))
    let seedMarker = try await harness.record(id: BookishRecordID("datastore-seed-marker"))

    #expect(allRecordsIndex?.kind == BookishRecordKind.index)
    #expect(bookLayout?.kind == BookishRecordKind.layout)
    #expect(sampleBook == nil)
    #expect(seedMarker?.string(BookishRecordKey.source) == nil)
  }

  @MainActor
  @Test

  func harnessPrunesStaleSeededBrowserIndexRecords() async throws {
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
    let harness = BookishHarness(directoryURL: directory)

    await harness.load()

    let names = harness.navigation.recordIndexes.map(\.name)
    let staleRecordIndex = try await harness.record(id: BookishRecordID("datastore-index-records"))
    let staleRecordIndexKind = try await harness.record(
      id: BookishRecordID("datastore-index-record-indexes"))
    let staleLayout = try await harness.record(id: BookishRecordID("datastore-book-compact-layout"))
    let relationshipLayout = try await harness.record(
      id: BookishRecordID("datastore-relationship-layout"))
    let relationshipsIndex = try await harness.record(
      id: BookishRecordID("datastore-index-relationships"))

    #expect(names.contains("Records") == false)
    #expect(staleRecordIndex == nil)
    #expect(staleRecordIndexKind == nil)
    #expect(staleLayout == nil)
    #expect(relationshipLayout == nil)
    #expect(relationshipsIndex == nil)
  }

  @MainActor
  @Test

  func selectionCommandsAreDisabledWithoutSelection() {
    let harness = BookishHarness()

    #expect(harness.availability(MarkReadingCommand()) == .disabled)
    #expect(harness.availability(MarkFinishedCommand()) == .disabled)
    #expect(harness.availability(SimulateRemoteMutationCommand()) == .disabled)
  }

  @MainActor
  @Test

  func navigationCommandsAreDisabledWithoutRecords() {
    let harness = BookishHarness()
    let navigation = BookishNavigationService()

    #expect(harness.availability(SelectNextRecordIndexCommand()) == .disabled)
    #expect(harness.availability(SelectPreviousRecordIndexCommand()) == .disabled)
    #expect(navigation.availability(SelectNextRecordCommand()) == .disabled)
    #expect(navigation.availability(SelectPreviousRecordCommand()) == .disabled)
  }

  @MainActor
  @Test

  func navigationServiceDefaultsToFirstIndexAndRecord() throws {
    let navigation = BookishNavigationService()
    let recordIndexResult = RecordQueryResult(query: RecordQuery())
    recordIndexResult.update(
      records: [
        try browserIndexRecord(id: "authors", name: "Authors", predicate: .kind("author")),
        try browserIndexRecord(id: "books", name: "Books", predicate: .kind("book")),
      ])
    let selectedRecordResult = RecordQueryResult(query: RecordQuery(predicate: .kind("author")))
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author")
    ])

    navigation.update(recordIndexResult: recordIndexResult)
    navigation.update(selectedRecordResult: selectedRecordResult)

    #expect(navigation.recordIndexes.map(\.name) == ["Authors", "Books"])
    #expect(navigation.selectedRecordIndexName == "Authors")
    #expect(navigation.selectedRecordID == BookishRecordID("author-1"))
    #expect(navigation.selectedRecordIDs == [BookishRecordID("author-1")])
  }

  @MainActor
  @Test

  func navigationCommandsMoveBetweenIndexesAndRecords() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    try await harness.perform(SelectNextRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Indexes")

    try await harness.perform(SelectPreviousRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Layouts")

    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
      BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)
    navigation.select(recordID: BookishRecordID("book-1"))

    try await navigation.perform(SelectNextRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-2"))

    try await navigation.perform(SelectPreviousRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-1"))
  }

  @MainActor
  @Test

  func selectedIndexProvidesDefaultLayout() async throws {
    let harness = try makeHarness()
    await harness.load()

    await harness.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    let layout = try await harness.selectedLayout()

    #expect(layout?.id == BookishRecordID("datastore-layout-layout"))
  }

  @MainActor
  @Test

  func navigateToRecordCommandSelectsTargetKindAndRecord() async throws {
    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)

    try await navigation.perform(NavigateToRecordCommand(recordID: BookishRecordID("book-1")))

    #expect(navigation.selectedRecordID == BookishRecordID("book-1"))
  }

  @MainActor
  @Test

  func exportCommandIsDisabledWithoutRecords() {
    let harness = BookishHarness()

    #expect(harness.availability(ExportInterchangeCommand()) == .disabled)
  }

  @MainActor
  @Test

  func localDatastoreDirectoryUsesInjectedDirectory() throws {
    let directory = try temporaryDirectory()
    let harness = BookishHarness(directoryURL: directory)

    #expect(try harness.localDatastoreDirectory() == directory)
    #expect(FileManager.default.fileExists(atPath: directory.path()))
  }

  @MainActor
  @Test

  func revealDatastoreFolderCommandIsAvailableOnMac() {
    let harness = BookishHarness()

    #expect(harness.availability(RevealDatastoreFolderCommand()) == .enabled)
  }

  @MainActor
  @Test

  func otherDeliciousLibraryImportCommandRequestsViewOwnedFilePicker() async throws {
    let harness = BookishHarness()

    try await harness.perform(ImportOtherDeliciousLibraryCommand())

    #expect(harness.isImportingDeliciousLibrary)
  }

  @MainActor
  @Test

  func deliciousLibrarySmallSampleCommandImportsBundledSample() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.perform(ImportDeliciousLibrarySampleCommand(sample: .small))

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(importedBooks.isEmpty == false)
  }

  @MainActor
  @Test

  func deliciousLibrarySampleCommandUsesMenuLabels() {
    let harness = BookishHarness()

    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .small).name(centre: harness) == "Small Sample")
    #expect(
      ImportDeliciousLibrarySampleCommand(sample: .full).name(centre: harness) == "Full Sample")
  }

  @MainActor
  @Test

  func testErrorCommandIsShownInStatusBar() async {
    let harness = BookishHarness()

    await harness.performWithoutWaiting(ThrowTestErrorCommand()).value

    #expect(harness.status == "This is a test command error.")
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

  func engineInjectsHarnessNavigationService() {
    let navigation = BookishNavigationService()
    let harness = BookishHarness(navigation: navigation)
    let engine = BookishEngine(harness: harness)

    #expect(engine.navigation === navigation)
    #expect(engine.harness.navigation === navigation)
  }

  @MainActor
  @Test

  func harnessImportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "ℹ": "test-import-book",
            "©": "book",
            "name": "Imported Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    let importedID = BookishRecordID("test-import-book")
    let importedName = try await harness.record(id: importedID)?.string("name")

    #expect(harness.navigation.recordIDs.contains(importedID))
    #expect(importedName == "Imported Book")
    #expect(harness.status == "Imported 1 Bookish interchange record")
  }

  @MainActor
  @Test

  func harnessImportsDeliciousLibraryData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try Data(contentsOf: deliciousSampleURL())

    await harness.importDeliciousLibrary(data: data)

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(importedBooks.isEmpty == false)
    #expect(harness.status.hasPrefix("Imported "))
    #expect(harness.status.contains("Delicious Library"))
  }

  @MainActor
  @Test

  func invalidDeliciousLibraryDataIsShownInStatusBar() async throws {
    let harness = try makeHarness()
    await harness.load()

    await harness.importDeliciousLibrary(data: Data("not a property list".utf8))

    #expect(harness.status != "Ready")
  }

  @MainActor
  @Test

  func harnessExportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try await harness.exportInterchangeData()
    let file = try BookishInterchangeCodec().decode(data)

    #expect(file.records.isEmpty == false)
    #expect(file.root == harness.navigation.selectedRecordID)
  }

  @MainActor
  @Test

  func rebuildCommandRebuildsRecordStoreFromMutationHistory() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "ℹ": "test-reset-book",
            "©": "book",
            "name": "Reset Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    let mutationsBeforeReset = try await harness.mutations()
    #expect(mutationsBeforeReset.isEmpty == false)

    try await harness.perform(RebuildRecordStoreCommand())

    let sampleBook = try await harness.record(id: BookishRecordID("seed-book"))
    let sampleAuthor = try await harness.record(id: BookishRecordID("seed-author"))
    let seedMarker = try await harness.record(id: BookishRecordID("datastore-seed-marker"))
    let allRecordsIndex = try await harness.record(
      id: BookishRecordID("datastore-index-all-records"))
    let bookLayout = try await harness.record(id: BookishRecordID("datastore-book-layout"))

    #expect(harness.navigation.recordIDs.isEmpty == false)
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    #expect(sampleBook?.kind == BookishRecordKind.book)
    #expect(sampleAuthor?.kind == BookishRecordKind.person)
    #expect(seedMarker?.kind == BookishRecordKind.seedMarker)
    #expect(allRecordsIndex?.kind == BookishRecordKind.index)
    #expect(bookLayout?.kind == BookishRecordKind.layout)
    let mutationsAfterReset = try await harness.mutations()
    #expect(mutationsAfterReset.map(\.id) == mutationsBeforeReset.map(\.id))
    #expect(mutationsAfterReset.map(\.operation) == mutationsBeforeReset.map(\.operation))
    #expect(harness.status == "Rebuilt record store")
  }

  @MainActor
  @Test

  func resetCommandResetsDatastore() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "ℹ": "test-command-reset-book",
            "©": "book",
            "name": "Command Reset Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    #expect(harness.navigation.recordIDs.isEmpty == false)

    try await harness.perform(ResetDatastoreCommand())

    let sampleBook = try await harness.record(id: BookishRecordID("seed-book"))
    let seedMarker = try await harness.record(id: BookishRecordID("datastore-seed-marker"))

    #expect(harness.navigation.recordIDs.isEmpty == false)
    #expect(sampleBook == nil)
    #expect(seedMarker?.kind == BookishRecordKind.seedMarker)
    let mutations = try await harness.mutations()
    #expect(mutations.isEmpty)
    #expect(harness.status == "Reset datastore")
  }

  @MainActor
  private func makeHarness(defaultShowsDebugIndexes: Bool = true) throws -> BookishHarness {
    BookishHarness(
      directoryURL: try temporaryDirectory(),
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
  }

  @MainActor
  private func records(for harness: BookishHarness) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.recordIDs {
      if let record = try await harness.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  @MainActor
  private func selectedRecords(for harness: BookishHarness) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.navigation.selectedRecordIDs {
      if let record = try await harness.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  private func temporaryDirectory() throws -> URL {
    let directory = URL.temporaryDirectory.appending(
      path: "BookishAppTests-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func deliciousSampleURL() throws -> URL {
    try BookishImporterSamples.deliciousLibraryURL(for: .small)
  }

  private func browserIndexRecord(
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
