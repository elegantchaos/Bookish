import BookishCoding
import BookishImporter
import BookishRecord
import Foundation
import Testing

@testable import BookishApp

@MainActor extension BookishAppTests {
  @Test func importerPersistsRecordsBeforeReportingTheirEvent() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let importer = BookishImportingService(storageService: storage)
    let importedID = BookishRecordID("test-import-service-book")
    var recordWasPersistedWhenReported = false

    let summary = try await importer.importRecords(
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

    #expect(summary.recordCount == 1)
    #expect(recordWasPersistedWhenReported)
  }

  @Test func importerReadsInterchangeFiles() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let importer = BookishImportingService(storageService: storage)
    let importedID = BookishRecordID("test-import-file-book")
    let fileURL = try temporaryDirectory().appending(path: "import.bookish.json")
    try Data(
      """
      { "records": [{ "ℹ": "test-import-file-book", "©": "book", "name": "Imported File" }] }
      """.utf8
    ).write(to: fileURL)

    let summary = try await importer.importInterchange(from: fileURL) { _ in }

    #expect(summary.recordCount == 1)
    #expect(try await storage.record(id: importedID)?.string("name") == "Imported File")
  }

  @Test func harnessImportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-import-book", "©": "book", "name": "Imported Book" }] }
      """
    await harness.importInterchange(data: Data(json.utf8))
    let importedID = BookishRecordID("test-import-book")
    #expect(harness.navigation.recordIDs.contains(importedID))
    #expect(
      try await harness.storageService.record(id: importedID)?.string("name") == "Imported Book")
    #expect(harness.statusService.message == "Imported 1 Bookish interchange record")
  }

  @Test func harnessImportsDeliciousLibraryData() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importDeliciousLibrary(data: try Data(contentsOf: deliciousSampleURL()))
    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string(BookishRecordKey.name) == "Snow Crash"
    }
    #expect(importedBooks.isEmpty == false)
    #expect(harness.statusService.message.hasPrefix("Imported "))
    #expect(harness.statusService.message.contains("Delicious Library"))
  }

  @Test func invalidDeliciousLibraryDataIsShownInStatusBar() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.importDeliciousLibrary(data: Data("not a property list".utf8))
    #expect(harness.statusService.message != "Ready")
  }

  @Test func exporterEncodesStorageRecordsAsInterchangeData() async throws {
    let storage = BookishStorageService(directoryURL: try temporaryDirectory())
    try await storage.load()
    let root = BookishRecordID("seed-book")
    let exporter = BookishExportingService(storageService: storage)

    let file = try BookishInterchangeCodec().decode(await exporter.interchangeData(root: root))
    #expect(file.records.isEmpty == false)
    #expect(file.root == root)
  }

  @Test func rebuildCommandRebuildsRecordStoreFromMutationHistory() async throws {
    let harness = try makeHarness()
    let commander = makeCommandCentre(for: harness)
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-reset-book", "©": "book", "name": "Reset Book" }] }
      """
    await harness.importInterchange(data: Data(json.utf8))
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    let mutationsBeforeReset = try await harness.storageService.mutations()
    #expect(mutationsBeforeReset.isEmpty == false)
    try await commander.perform(RebuildRecordStoreCommand())
    #expect(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    #expect(
      try await harness.storageService.record(id: BookishRecordID("seed-book"))?.kind
        == BookishRecordKind.book)
    #expect(
      try await harness.storageService.record(id: BookishRecordID("seed-author"))?.kind
        == BookishRecordKind.person
    )
    #expect(
      try await harness.storageService.record(id: BookishRecordID("datastore-seed-marker"))?.kind
        == BookishRecordKind.seedMarker)
    #expect(
      try await harness.storageService.record(id: BookishRecordID("datastore-index-all-records"))?
        .kind
        == BookishRecordKind.index)
    #expect(
      try await harness.storageService.record(id: BookishRecordID("datastore-book-layout"))?.kind
        == BookishRecordKind.layout)
    let mutationsAfterReset = try await harness.storageService.mutations()
    #expect(mutationsAfterReset.map(\.id) == mutationsBeforeReset.map(\.id))
    #expect(mutationsAfterReset.map(\.operation) == mutationsBeforeReset.map(\.operation))
    #expect(harness.statusService.message == "Rebuilt record store")
  }

  @Test func resetCommandResetsDatastore() async throws {
    let harness = try makeHarness()
    let commander = makeCommandCentre(for: harness)
    await harness.load()
    let json = """
      { "records": [{ "ℹ": "test-command-reset-book", "©": "book", "name": "Command Reset Book" }] }
      """
    await harness.importInterchange(data: Data(json.utf8))
    #expect(harness.navigation.recordIDs.isEmpty == false)
    try await commander.perform(ResetDatastoreCommand())
    #expect(harness.navigation.recordIDs.isEmpty == false)
    #expect(try await harness.storageService.record(id: BookishRecordID("seed-book")) == nil)
    #expect(
      try await harness.storageService.record(id: BookishRecordID("datastore-seed-marker"))?.kind
        == BookishRecordKind.seedMarker)
    #expect((try await harness.storageService.mutations()).isEmpty)
    #expect(harness.statusService.message == "Reset datastore")
  }
}
