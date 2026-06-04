import BookishCoding
import BookishRecord
import Commands
import XCTest

@testable import DatastorePrototypeApp

final class DatastorePrototypeAppTests: XCTestCase {
  @MainActor
  func testHarnessStartsInLoadingState() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.status, "Loading")
    XCTAssertTrue(harness.recordIDs.isEmpty)
    XCTAssertTrue(harness.mutations.isEmpty)
  }

  @MainActor
  func testSelectionCommandsAreDisabledWithoutSelection() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.availability(MarkReadingCommand()), .disabled)
    XCTAssertEqual(harness.availability(MarkFinishedCommand()), .disabled)
    XCTAssertEqual(harness.availability(SimulateRemoteMutationCommand()), .disabled)
  }

  @MainActor
  func testExportCommandIsDisabledWithoutRecords() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.availability(ExportInterchangeCommand()), .disabled)
  }

  @MainActor
  func testLocalDatastoreDirectoryUsesInjectedDirectory() throws {
    let directory = try temporaryDirectory()
    let harness = DatastorePrototypeHarness(directoryURL: directory)

    XCTAssertEqual(try harness.localDatastoreDirectory(), directory)
    XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path()))
  }

  @MainActor
  func testRevealDatastoreFolderCommandIsAvailableOnMac() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.availability(RevealDatastoreFolderCommand()), .enabled)
  }

  @MainActor
  func testEngineUsesApplicationStartupLoop() {
    let engine = DatastorePrototypeEngine()

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

    XCTAssertTrue(harness.recordIDs.contains(importedID))
    XCTAssertEqual(importedTitle, "Imported Book")
    XCTAssertEqual(harness.status, "Imported 1 interchange record")
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
  func testHarnessExportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try await harness.exportInterchangeData()
    let file = try BookishInterchangeCodec().decode(data)

    XCTAssertFalse(file.records.isEmpty)
    XCTAssertEqual(file.root, harness.selectedRecordID)
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

    XCTAssertTrue(harness.recordIDs.contains(BookishRecordID("test-reset-book")))
    XCTAssertFalse(harness.mutations.isEmpty)

    await harness.reset()

    XCTAssertTrue(harness.recordIDs.isEmpty)
    XCTAssertFalse(harness.recordIDs.contains(BookishRecordID("test-reset-book")))
    XCTAssertTrue(harness.mutations.isEmpty)
    XCTAssertEqual(harness.status, "Reset prototype datastore")
  }

  @MainActor
  func testResetCommandResetsPrototypeDatastore() async throws {
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

    XCTAssertFalse(harness.recordIDs.isEmpty)

    try await harness.perform(ResetPrototypeCommand())

    XCTAssertTrue(harness.recordIDs.isEmpty)
    XCTAssertTrue(harness.mutations.isEmpty)
    XCTAssertEqual(harness.status, "Reset prototype datastore")
  }

  @MainActor
  private func makeHarness() throws -> DatastorePrototypeHarness {
    DatastorePrototypeHarness(directoryURL: try temporaryDirectory())
  }

  @MainActor
  private func records(for harness: DatastorePrototypeHarness) async throws -> [BookishRecord] {
    var records: [BookishRecord] = []
    for id in harness.recordIDs {
      if let record = try await harness.record(id: id) {
        records.append(record)
      }
    }
    return records
  }

  private func temporaryDirectory() throws -> URL {
    let directory = URL.temporaryDirectory.appending(
      path: "DatastorePrototypeAppTests-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func deliciousSampleURL() -> URL {
    let testFile = URL(fileURLWithPath: #filePath)
    let packageRoot =
      testFile
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    return
      packageRoot
      .deletingLastPathComponent()
      .appending(path: "BookishImporter")
      .appending(path: "Sources")
      .appending(path: "BookishImporterSamples")
      .appending(path: "Resources")
      .appending(path: "DeliciousSmall.xml")
  }
}
