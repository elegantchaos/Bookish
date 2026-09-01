import BookishCoding
import BookishImporterSamples
import BookishRecord
import Commands
import XCTest

@testable import BookishApp

final class BookishAppTests: XCTestCase {
  @MainActor
  func testHarnessStartsInLoadingState() {
    let harness = BookishHarness()

    XCTAssertEqual(harness.status, "Loading")
    XCTAssertTrue(harness.navigation.recordIDs.isEmpty)
  }

  @MainActor
  func testSelectionCommandsAreDisabledWithoutSelection() {
    let harness = BookishHarness()

    XCTAssertEqual(harness.availability(MarkReadingCommand()), .disabled)
    XCTAssertEqual(harness.availability(MarkFinishedCommand()), .disabled)
    XCTAssertEqual(harness.availability(SimulateRemoteMutationCommand()), .disabled)
  }

  @MainActor
  func testNavigationCommandsAreDisabledWithoutRecords() {
    let navigation = BookishNavigationService()

    XCTAssertEqual(navigation.availability(SelectNextRecordKindCommand()), .disabled)
    XCTAssertEqual(navigation.availability(SelectPreviousRecordKindCommand()), .disabled)
    XCTAssertEqual(navigation.availability(SelectNextRecordCommand()), .disabled)
    XCTAssertEqual(navigation.availability(SelectPreviousRecordCommand()), .disabled)
  }

  @MainActor
  func testNavigationServiceDefaultsToFirstKindAndRecord() {
    let navigation = BookishNavigationService()

    navigation.update(
      records: [
        BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
        BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
        BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
      ])

    XCTAssertEqual(navigation.recordKinds, ["author", "book"])
    XCTAssertEqual(navigation.selectedRecordKind, "author")
    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("author-1"))
    XCTAssertEqual(navigation.selectedRecordIDs, [BookishRecordID("author-1")])
  }

  @MainActor
  func testNavigationCommandsMoveBetweenKindsAndRecords() async throws {
    let navigation = BookishNavigationService()
    navigation.update(
      records: [
        BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
        BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
        BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
      ])

    try await navigation.perform(SelectNextRecordKindCommand())

    XCTAssertEqual(navigation.selectedRecordKind, "book")
    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("book-1"))

    try await navigation.perform(SelectNextRecordCommand())

    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("book-2"))

    try await navigation.perform(SelectPreviousRecordCommand())

    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("book-1"))

    try await navigation.perform(SelectPreviousRecordKindCommand())

    XCTAssertEqual(navigation.selectedRecordKind, "author")
    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("author-1"))
  }

  @MainActor
  func testNavigateToRecordCommandSelectsTargetKindAndRecord() async throws {
    let navigation = BookishNavigationService()
    navigation.update(
      records: [
        BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
        BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
      ])

    try await navigation.perform(NavigateToRecordCommand(recordID: BookishRecordID("book-1")))

    XCTAssertEqual(navigation.selectedRecordKind, "book")
    XCTAssertEqual(navigation.selectedRecordID, BookishRecordID("book-1"))
  }

  @MainActor
  func testExportCommandIsDisabledWithoutRecords() {
    let harness = BookishHarness()

    XCTAssertEqual(harness.availability(ExportInterchangeCommand()), .disabled)
  }

  @MainActor
  func testLocalDatastoreDirectoryUsesInjectedDirectory() throws {
    let directory = try temporaryDirectory()
    let harness = BookishHarness(directoryURL: directory)

    XCTAssertEqual(try harness.localDatastoreDirectory(), directory)
    XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path()))
  }

  @MainActor
  func testRevealDatastoreFolderCommandIsAvailableOnMac() {
    let harness = BookishHarness()

    XCTAssertEqual(harness.availability(RevealDatastoreFolderCommand()), .enabled)
  }

  @MainActor
  func testOtherDeliciousLibraryImportCommandRequestsViewOwnedFilePicker() async throws {
    let harness = BookishHarness()

    try await harness.perform(ImportOtherDeliciousLibraryCommand())

    XCTAssertTrue(harness.isImportingDeliciousLibrary)
  }

  @MainActor
  func testDeliciousLibrarySmallSampleCommandImportsBundledSample() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.perform(ImportDeliciousLibrarySampleCommand(sample: .small))

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string("title") == "Snow Crash"
    }
    XCTAssertFalse(importedBooks.isEmpty)
  }

  @MainActor
  func testDeliciousLibrarySampleCommandUsesMenuLabels() {
    let harness = BookishHarness()

    XCTAssertEqual(
      ImportDeliciousLibrarySampleCommand(sample: .small).name(centre: harness), "Small Sample")
    XCTAssertEqual(
      ImportDeliciousLibrarySampleCommand(sample: .full).name(centre: harness), "Full Sample")
  }

  @MainActor
  func testTestErrorCommandIsShownInStatusBar() async {
    let harness = BookishHarness()

    await harness.performWithoutWaiting(ThrowTestErrorCommand()).value

    XCTAssertEqual(harness.status, "This is a test command error.")
  }

  @MainActor
  func testEngineUsesApplicationStartupLoop() {
    let engine = BookishEngine()

    guard case .uninitialised = engine.state else {
      XCTFail("Expected engine to start uninitialised.")
      return
    }

    engine.start()

    guard case .starting = engine.state else {
      XCTFail("Expected engine to enter startup.")
      return
    }
    XCTAssertNotNil(engine.startupTask)
  }

  @MainActor
  func testEngineInjectsHarnessNavigationService() {
    let navigation = BookishNavigationService()
    let harness = BookishHarness(navigation: navigation)
    let engine = BookishEngine(harness: harness)

    XCTAssertTrue(engine.navigation === navigation)
    XCTAssertTrue(engine.harness.navigation === navigation)
  }

  @MainActor
  func testHarnessImportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "id": "test-import-book",
            "kind": "book",
            "title": "Imported Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    let importedID = BookishRecordID("test-import-book")
    let importedTitle = try await harness.record(id: importedID)?.string("title")

    XCTAssertTrue(harness.navigation.recordIDs.contains(importedID))
    XCTAssertEqual(importedTitle, "Imported Book")
    XCTAssertEqual(harness.status, "Imported 1 Bookish interchange record")
  }

  @MainActor
  func testHarnessImportsDeliciousLibraryData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try Data(contentsOf: deliciousSampleURL())

    await harness.importDeliciousLibrary(data: data)

    let importedBooks = try await records(for: harness).filter {
      $0.kind == "book" && $0.string("title") == "Snow Crash"
    }
    XCTAssertFalse(importedBooks.isEmpty)
    XCTAssertTrue(harness.status.hasPrefix("Imported "))
    XCTAssertTrue(harness.status.contains("Delicious Library"))
  }

  @MainActor
  func testInvalidDeliciousLibraryDataIsShownInStatusBar() async throws {
    let harness = try makeHarness()
    await harness.load()

    await harness.importDeliciousLibrary(data: Data("not a property list".utf8))

    XCTAssertNotEqual(harness.status, "Ready")
  }

  @MainActor
  func testHarnessExportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try await harness.exportInterchangeData()
    let file = try BookishInterchangeCodec().decode(data)

    XCTAssertFalse(file.records.isEmpty)
    XCTAssertEqual(file.root, harness.navigation.selectedRecordID)
  }

  @MainActor
  func testHarnessResetRemovesImportedRecordsAndMutationHistory() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "id": "test-reset-book",
            "kind": "book",
            "title": "Reset Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    XCTAssertTrue(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    let mutationsBeforeReset = try await harness.mutations()
    XCTAssertFalse(mutationsBeforeReset.isEmpty)

    await harness.reset()

    XCTAssertTrue(harness.navigation.recordIDs.isEmpty)
    XCTAssertFalse(harness.navigation.recordIDs.contains(BookishRecordID("test-reset-book")))
    let mutationsAfterReset = try await harness.mutations()
    XCTAssertTrue(mutationsAfterReset.isEmpty)
    XCTAssertEqual(harness.status, "Reset datastore")
  }

  @MainActor
  func testResetCommandResetsDatastore() async throws {
    let harness = try makeHarness()
    await harness.load()

    let json = """
      {
        "records": [
          {
            "id": "test-command-reset-book",
            "kind": "book",
            "title": "Command Reset Book"
          }
        ]
      }
      """

    await harness.importInterchange(data: Data(json.utf8))

    XCTAssertFalse(harness.navigation.recordIDs.isEmpty)

    try await harness.perform(ResetDatastoreCommand())

    XCTAssertTrue(harness.navigation.recordIDs.isEmpty)
    let mutations = try await harness.mutations()
    XCTAssertTrue(mutations.isEmpty)
    XCTAssertEqual(harness.status, "Reset datastore")
  }

  @MainActor
  private func makeHarness() throws -> BookishHarness {
    BookishHarness(directoryURL: try temporaryDirectory())
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
}
