import BookishCoding
import BookishImporterSamples
import BookishRecord
import Foundation
import XCTest

@testable import BookishImporter

final class DeliciousLibraryImporterTests: XCTestCase {
  func testImportsDeliciousSmallAsNormalisedGraph() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())

    XCTAssertEqual(result.sourceID, DeliciousLibraryImporter.sourceID)
    XCTAssertEqual(result.root, BookishRecordID("delicious-import"))
    XCTAssertTrue(result.diagnostics.isEmpty)

    let recordsByID = Dictionary(uniqueKeysWithValues: result.records.map { ($0.id, $0) })
    let snowCrash = try XCTUnwrap(
      result.records.first { $0.string("title") == "Snow Crash" && $0.kind == "book" }
    )

    XCTAssertEqual(snowCrash.string("isbn"), "0140232923")
    XCTAssertEqual(snowCrash.integer("pages"), 448)
    XCTAssertEqual(snowCrash.string("source"), DeliciousLibraryImporter.sourceID)
    XCTAssertEqual(snowCrash.list("imageURLs")?.count, 3)

    let authorID = try XCTUnwrap(snowCrash.list("authors")?.first?.recordValue)
    let author = try XCTUnwrap(recordsByID[authorID])
    XCTAssertEqual(author.kind, "person")
    XCTAssertEqual(author.string("name"), "Neal Stephenson")

    let publisherID = try XCTUnwrap(snowCrash.list("publishers")?.first?.recordValue)
    let publisher = try XCTUnwrap(recordsByID[publisherID])
    XCTAssertEqual(publisher.kind, "organisation")
    XCTAssertEqual(publisher.string("name"), "RoC")

    XCTAssertFalse(result.records.contains { $0.kind == "relationship" })
  }

  func testImportsSeriesRecordsAndDirectReference() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())
    let gameOfThrones = try XCTUnwrap(
      result.records.first { $0.string("title") == "A Game of Thrones" && $0.kind == "book" }
    )

    let seriesID = try XCTUnwrap(gameOfThrones.record("series"))
    let series = try XCTUnwrap(result.records.first { $0.id == seriesID })

    XCTAssertEqual(series.kind, "series")
    XCTAssertEqual(series.string("name"), "A Song of Ice and Fire")
    XCTAssertEqual(gameOfThrones.integer("seriesPosition"), 1)
  }

  func testImportIsDeterministic() throws {
    let importer = DeliciousLibraryImporter()
    let first = try importer.importRecords(from: deliciousSampleURL())
    let second = try importer.importRecords(from: deliciousSampleURL())

    XCTAssertEqual(first, second)
  }

  func testImportedRecordsRoundTripThroughInterchangeCoding() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())
    let file = BookishInterchangeFile(root: result.root, records: result.records)
    let data = try BookishInterchangeCodec(recordLinkEncoding: .shorthand).encode(file)
    let decoded = try BookishInterchangeCodec().decode(data)

    XCTAssertEqual(decoded.root, result.root)
    XCTAssertEqual(decoded.records, result.records)
  }

  private func deliciousSampleURL() throws -> URL {
    try BookishImporterSamples.deliciousLibraryURL(for: .small)
  }
}
