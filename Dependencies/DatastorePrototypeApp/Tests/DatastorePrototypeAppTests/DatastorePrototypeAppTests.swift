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
    let harness = DatastorePrototypeHarness()
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
    let harness = DatastorePrototypeHarness()
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
    let harness = DatastorePrototypeHarness()
    await harness.load()

    let data = try harness.exportInterchangeData()
    let file = try BookishInterchangeCodec().decode(data)

    XCTAssertFalse(file.records.isEmpty)
    XCTAssertEqual(file.root, harness.selectedRecord?.id)
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
