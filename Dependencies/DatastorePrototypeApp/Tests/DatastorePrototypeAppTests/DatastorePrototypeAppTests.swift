import BookishCoding
import BookishRecord
import XCTest

@testable import DatastorePrototypeApp

final class DatastorePrototypeAppTests: XCTestCase {
  @MainActor
  func testHarnessStartsInLoadingState() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.status, "Loading")
    XCTAssertTrue(harness.records.isEmpty)
    XCTAssertTrue(harness.mutations.isEmpty)
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

    XCTAssertTrue(harness.records.contains { $0.id == BookishRecordID("test-import-book") })
    XCTAssertEqual(harness.status, "Imported 1 interchange record")
  }

  @MainActor
  func testHarnessImportsDeliciousLibraryData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try Data(contentsOf: deliciousSampleURL())

    await harness.importDeliciousLibrary(data: data)

    XCTAssertTrue(
      harness.records.contains { $0.kind == "book" && $0.string("title") == "Snow Crash" })
    XCTAssertTrue(harness.status.hasPrefix("Imported "))
    XCTAssertTrue(harness.status.contains("Delicious Library"))
  }

  @MainActor
  func testHarnessExportsInterchangeData() async throws {
    let harness = try makeHarness()
    await harness.load()

    let data = try harness.exportInterchangeData()
    let file = try BookishInterchangeCodec().decode(data)

    XCTAssertFalse(file.records.isEmpty)
    XCTAssertEqual(file.root, harness.selectedRecord?.id)
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

    XCTAssertTrue(harness.records.contains { $0.id == BookishRecordID("test-reset-book") })
    XCTAssertFalse(harness.mutations.isEmpty)

    await harness.reset()

    XCTAssertTrue(harness.records.isEmpty)
    XCTAssertFalse(harness.records.contains { $0.id == BookishRecordID("test-reset-book") })
    XCTAssertTrue(harness.mutations.isEmpty)
    XCTAssertEqual(harness.status, "Reset prototype datastore")
  }

  @MainActor
  private func makeHarness() throws -> DatastorePrototypeHarness {
    DatastorePrototypeHarness(directoryURL: try temporaryDirectory())
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
