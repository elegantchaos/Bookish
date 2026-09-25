import BookishCoding
import BookishDatastore
import BookishImporter
import BookishRecord
import Foundation
import Testing

@testable import BookishApp

@MainActor extension BookishAppTests {
  @Test func importerPreparesRecordsBeforeApplyingThem() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let storage = engine.storage
    try await storage.load()
    let importer = engine.importing
    let importedID = BookishRecordID("test-import-service-book")
    var recordWasPersistedWhenReported = false

    let plan = try await importer.importRecords(
      from: Data(
        """
        { "records": [{ "ℹ": "test-import-service-book", "©": "book", "name": "Imported Book" }] }
        """.utf8),
      using: BookishInterchangeImporter()
    ) { event in
      if case .records = event {
        recordWasPersistedWhenReported = try await storage.record(id: importedID) != nil
      }
    }

    #expect(plan.entries.count == 1)
    #expect(!recordWasPersistedWhenReported)
    #expect(try await storage.record(id: importedID) == nil)
    let resolution = try await importer.apply(plan, choices: [:])
    #expect(resolution.records.count == 1)
    #expect(try await storage.record(id: importedID) != nil)
  }

  @Test func importerReadsInterchangeFiles() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let storage = engine.storage
    try await storage.load()
    let importer = engine.importing
    let importedID = BookishRecordID("test-import-file-book")
    let fileURL = try temporaryDirectory().appending(path: "import.bookish.json")
    try Data(
      """
      { "records": [{ "ℹ": "test-import-file-book", "©": "book", "name": "Imported File" }] }
      """.utf8
    ).write(to: fileURL)

    let plan = try await importer.importInterchange(from: fileURL) { _ in }

    #expect(plan.entries.count == 1)
    #expect(try await storage.record(id: importedID) == nil)
    _ = try await importer.apply(plan, choices: [:])
    #expect(try await storage.record(id: importedID)?.string("name") == "Imported File")
  }

  @Test func repeatedInterchangeImportAddsNoMutations() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let storage = engine.storage
    try await storage.load()
    let importer = engine.importing
    let data = Data(
      """
      { "records": [{ "ℹ": "repeat-book", "©": "book", "name": "Repeated Book" }] }
      """.utf8)

    let first = try await importer.importRecords(from: data, using: BookishInterchangeImporter()) {
      _ in
    }
    _ = try await importer.apply(first, choices: [:])
    let mutations = try await storage.mutations().count
    let second = try await importer.importRecords(from: data, using: BookishInterchangeImporter()) {
      _ in
    }
    #expect(second.skippedCount == 1)
    #expect(try await importer.apply(second, choices: [:]).records.isEmpty)
    #expect(try await storage.mutations().count == mutations)
  }

  @Test func changedCatalogueRejectsStaleImportPlan() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let storage = engine.storage
    try await storage.load()
    let importer = engine.importing
    let data = Data(
      """
      { "records": [{ "ℹ": "stale-book", "©": "book", "name": "Stale Book" }] }
      """.utf8)
    let plan = try await importer.importRecords(from: data, using: BookishInterchangeImporter()) {
      _ in
    }
    try await storage.upsert(records: [
      BookishRecord(
        id: BookishRecordID("concurrent-book"), kind: BookishRecordKind.book,
        properties: [BookishRecordKey.name: .string("Concurrent Book")])
    ])

    await #expect(throws: BookishImportingError.self) {
      try await importer.apply(plan, choices: [:])
    }
    #expect(try await storage.record(id: BookishRecordID("stale-book")) == nil)
  }

  @Test func harnessImportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-import-book", "©": "book", "name": "Imported Book" }] }
      """
    await harness.importing.importInterchange(data: Data(json.utf8))
    #expect(harness.importing.state.pendingImportPlan != nil)
    #expect(harness.navigation.selectedMainSection == .importing)
    await harness.importing.applyPendingImport(choices: [:])
    let importedID = BookishRecordID("test-import-book")
    #expect(harness.navigation.recordIDs.contains(importedID))
    #expect(
      try await harness.storage.record(id: importedID)?.string("name") == "Imported Book")
    #expect(harness.status.state.message == "Imported 1 Bookish interchange record")
    #expect(harness.navigation.selectedMainSection == .importing)
    #expect(harness.importing.state.lastImportResult?.importedRecords.map(\.id) == [importedID])
  }

  @Test func reviewDefaultsToExistingAndBulkChoiceChangesOnlySelectedRows() async throws {
    let harness = try makeHarness()
    await harness.load()
    let existingID = BookishRecordID("existing-asin-book")
    try await harness.storage.upsert(records: [
      BookishRecord(
        id: existingID, kind: BookishRecordKind.book,
        properties: [
          BookishRecordKey.name: .string("Existing Book"),
          BookishRecordKey.asin: .string("B000000001"),
        ])
    ])
    let proposedID = BookishRecordID("proposed-asin-book")
    await harness.importing.importInterchange(
      data: Data(
        """
        { "records": [{ "ℹ": "proposed-asin-book", "©": "book", "name": "Proposed Book", "asin": "B000000001" }] }
        """.utf8))

    #expect(harness.importing.state.importChoices[proposedID] == .useExisting(existingID))
    #expect(harness.importing.canApplyPendingImport)
    harness.importing.state.setImportChoices(for: [proposedID], preferring: .imported)
    #expect(harness.importing.state.importChoices[proposedID] == .create)
    harness.importing.state.setImportChoices(for: [proposedID], preferring: .existing)
    await harness.importing.applyPendingImport()
    #expect(try await harness.storage.record(id: proposedID) == nil)
    #expect(harness.importing.state.lastImportResult?.reusedCount == 1)
    #expect(harness.importing.state.lastImportResult?.importedRecords.isEmpty == true)
  }

  @Test func newRecordsCanBeSkipped() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importing.importInterchange(
      data: Data(
        """
        { "records": [
          { "ℹ": "kept-book", "©": "book", "name": "Kept Book" },
          { "ℹ": "dropped-book", "©": "book", "name": "Dropped Book" }
        ] }
        """.utf8))
    let kept = BookishRecordID("kept-book")
    let dropped = BookishRecordID("dropped-book")

    #expect(harness.importing.state.importChoices == [kept: .create, dropped: .create])
    harness.importing.state.setImportChoice(
      .skip, for: [kept, dropped, BookishRecordID("not-in-plan")])
    #expect(harness.importing.state.importChoices == [kept: .skip, dropped: .skip])
    harness.importing.state.setImportChoice(.create, for: [kept])
    harness.importing.state.setImportChoice(.keepExisting, for: [dropped])
    #expect(harness.importing.state.importChoices[dropped] == .skip)
    #expect(harness.importing.canApplyPendingImport)
    await harness.importing.applyPendingImport()

    #expect(try await harness.storage.record(id: kept) != nil)
    #expect(try await harness.storage.record(id: dropped) == nil)
    #expect(harness.importing.state.lastImportResult?.importedRecords.map(\.id) == [kept])
    #expect(harness.importing.state.importChoices.isEmpty)

    let importRecords = try await records(for: harness).filter {
      $0.kind == BookishRecordKind.importRecord
    }
    #expect(importRecords.count == 1)
    #expect(importRecords.first?.date(BookishRecordKey.importDate) != nil)
    #expect(importRecords.first?.list(BookishRecordKey.importAdded) == [.record(kept)])
    #expect(importRecords.first?.list(BookishRecordKey.importMatched) == nil)
  }

  @Test func importWithEveryRecordSkippedWritesNoImportRecord() async throws {
    let harness = try makeHarness()
    await harness.load()
    let before = try await records(for: harness).count
    await harness.importing.importInterchange(
      data: Data(
        """
        { "records": [{ "ℹ": "skipped-book", "©": "book", "name": "Skipped Book" }] }
        """.utf8))
    harness.importing.state.setImportChoice(.skip, for: [BookishRecordID("skipped-book")])
    await harness.importing.applyPendingImport()

    #expect(try await records(for: harness).count == before)
  }

  @Test func harnessImportsDeliciousLibraryData() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importing.importDeliciousLibrary(data: try Data(contentsOf: deliciousSampleURL()))
    let plan = try #require(harness.importing.state.pendingImportPlan)
    let choices = Dictionary(
      uniqueKeysWithValues: plan.reviewEntries.map { entry in
        (entry.id, BookishImportChoice.create)
      })
    await harness.importing.applyPendingImport(choices: choices)
    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(!importedBooks.isEmpty)
    #expect(harness.status.state.message.hasPrefix("Imported "))
    #expect(harness.status.state.message.contains("Delicious Library"))
  }

  @Test func invalidDeliciousLibraryDataIsShownInStatusBar() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importing.importDeliciousLibrary(data: Data("not a property list".utf8))
    #expect(harness.status.state.message != "Ready")
  }

  @Test func exporterEncodesStorageRecordsAsInterchangeData() async throws {
    let engine = makeEngine(directoryURL: try temporaryDirectory())
    let storage = engine.storage
    try await storage.load()
    let root = BookishRecordID("seed-book")
    let exporter = engine.exporting

    let file = try BookishInterchangeCodec().decode(await exporter.interchangeData(root: root))
    #expect(!file.records.isEmpty)
    #expect(file.root == root)
  }

  @Test func rebuildCommandRebuildsRecordStoreFromMutationHistory() async throws {
    let harness = try makeHarness()
    let commander = harness
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-reset-book", "©": "book", "name": "Reset Book" }] }
      """
    await harness.importing.importInterchange(data: Data(json.utf8))
    await harness.importing.applyPendingImport(choices: [:])
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    let mutationsBeforeReset = try await harness.storage.mutations()
    #expect(!mutationsBeforeReset.isEmpty)
    try await commander.perform(RebuildRecordStoreCommand())
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    #expect(
      try await harness.storage.record(id: BookishRecordID("seed-book"))?.kind
        == BookishRecordKind.book)
    #expect(
      try await harness.storage.record(id: BookishRecordID("seed-author"))?.kind
        == BookishRecordKind.person
    )
    #expect(
      try await harness.storage.record(id: BookishRecordID("datastore-seed-marker"))?.kind
        == BookishRecordKind.seedMarker)
    #expect(
      try await harness.storage.record(id: BookishRecordID("datastore-index-all-records"))?
        .kind
        == BookishRecordKind.index)
    #expect(
      try await harness.storage.record(id: BookishRecordID("datastore-book-layout"))?.kind
        == BookishRecordKind.layout)
    let mutationsAfterReset = try await harness.storage.mutations()
    #expect(mutationsAfterReset.map(\.id) == mutationsBeforeReset.map(\.id))
    #expect(mutationsAfterReset.map(\.operation) == mutationsBeforeReset.map(\.operation))
    #expect(harness.status.state.message == "Rebuilt record store")
  }

  @Test func resetCommandResetsDatastore() async throws {
    let harness = try makeHarness()
    let commander = harness
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-command-reset-book", "©": "book", "name": "Command Reset Book" }] }
      """
    await harness.importing.importInterchange(data: Data(json.utf8))
    await harness.importing.applyPendingImport(choices: [:])
    #expect(!harness.navigation.recordIDs.isEmpty)
    harness.navigation.select(recordID: BookishRecordID("test-command-reset-book"))
    #expect(harness.navigation.selectedRecordID == BookishRecordID("test-command-reset-book"))
    try await commander.perform(ResetDatastoreCommand())
    #expect(!harness.navigation.recordIDs.contains(BookishRecordID("test-command-reset-book")))
    #expect(harness.navigation.selectedRecordID == nil)
    #expect(try await harness.storage.record(id: BookishRecordID("seed-book")) == nil)
    #expect(
      try await harness.storage.record(id: BookishRecordID("datastore-seed-marker"))?.kind
        == BookishRecordKind.seedMarker)
    #expect((try await harness.storage.mutations()).isEmpty)
    #expect(harness.status.state.message == "Reset datastore")
  }

  @Test func resetEmptiesSelectedNonBookIndex() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importing.importInterchange(
      data: Data(
        """
        { "records": [{ "ℹ": "reset-list", "©": "list", "name": "Reset List" }] }
        """.utf8))
    await harness.importing.applyPendingImport(choices: [:])
    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-lists"))
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("reset-list")))

    try await harness.perform(ResetDatastoreCommand())

    #expect(harness.navigation.selectedRecordIndexID == BookishRecordID("datastore-index-lists"))
    #expect(harness.navigation.recordIDs.isEmpty)
  }

  @Test func recordQueryResultFollowsResetAndLaterMutations() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let query = RecordQuery(predicate: .kind(BookishRecordKind.book), sort: [.id])
    let result = try await storage.recordQueryResult(matching: query)
    let book = BookishRecord(id: BookishRecordID("after-reset"), kind: BookishRecordKind.book)

    try await storage.upsert(records: [book])
    #expect(result.records.contains(book))

    try await storage.reset()
    #expect(result.records.isEmpty)
    #expect(try await storage.recordQueryResult(matching: query) === result)

    try await storage.upsert(records: [book])
    #expect(result.records == [book])
  }

  @Test func recordQueryResultFollowsProjectionRebuild() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let query = RecordQuery(predicate: .kind(BookishRecordKind.book), sort: [.id])
    let result = try await storage.recordQueryResult(matching: query)
    let book = BookishRecord(id: BookishRecordID("rebuilt-book"), kind: BookishRecordKind.book)
    try await storage.upsert(records: [book])

    try await storage.rebuildRecordProjection()

    #expect(result.records.contains(book))
    #expect(try await storage.recordQueryResult(matching: query) === result)
    let revision = result.revision
    try await storage.upsert(records: [
      BookishRecord(id: BookishRecordID("unrelated-person"), kind: BookishRecordKind.person)
    ])
    #expect(result.revision == revision)
  }
}
