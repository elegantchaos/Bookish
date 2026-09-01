import Foundation
import XCTest

@testable import BookishRecord

final class BookishRecordTests: XCTestCase {
  func testStandardKindsAndKeysHaveStableValues() {
    XCTAssertEqual(BookishRecordKind.book, "book")
    XCTAssertEqual(BookishRecordKind.person, "person")
    XCTAssertEqual(BookishRecordKind.organisation, "organisation")
    XCTAssertEqual(BookishRecordKey.authors, "authors")
    XCTAssertEqual(BookishRecordKey.series, "series")
    XCTAssertEqual(BookishRecordKey.seriesPosition, "seriesPosition")
    XCTAssertEqual(BookishRecordKey.isbn, "isbn")
  }

  func testRecordConstructionAndConvenienceReaders() {
    let authorID = BookishRecordID("person-1")
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "title": .string("Bookish"),
        "pages": .integer(320),
        "authors": .list([.record(authorID)]),
        "primaryAuthor": .record(authorID),
      ]
    )

    XCTAssertEqual(record.id.rawValue, "book-1")
    XCTAssertEqual(record.kind, "book")
    XCTAssertEqual(record.string("title"), "Bookish")
    XCTAssertEqual(record.integer("pages"), 320)
    XCTAssertEqual(record.record("primaryAuthor"), authorID)
    XCTAssertEqual(record.list("authors"), [.record(authorID)])
  }

  func testRecordValueSupportsNestedListsAndEncodedValues() throws {
    let dimensions = try BookishEncodedValue(encoding: Dimensions(width: 12, height: 20))
    let value = BookishRecordValue.list([
      .record(BookishRecordID("person-1")),
      .encoded(dimensions),
    ])

    XCTAssertEqual(
      value,
      .list([
        .record(BookishRecordID("person-1")),
        .encoded(dimensions),
      ])
    )
  }

  func testRecordCanReadEncodedPayloads() throws {
    let dimensions = Dimensions(width: 12, height: 20)
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "dimensions": .encoded(try BookishEncodedValue(encoding: dimensions)),
        "title": .string("Bookish"),
      ]
    )

    let inferred: Dimensions? = record.encoded("dimensions")

    XCTAssertEqual(inferred, dimensions)
    XCTAssertEqual(record.encoded("dimensions", as: Dimensions.self), dimensions)
    XCTAssertNil(record.encoded("missing", as: Dimensions.self))
    XCTAssertNil(record.encoded("title", as: Dimensions.self))
  }

  func testEncodedValueCanRoundTripCodablePayload() throws {
    let dimensions = Dimensions(width: 12, height: 20)
    let encoded = try BookishEncodedValue(encoding: dimensions)
    let decoded = try encoded.decode(Dimensions.self)

    XCTAssertEqual(decoded, dimensions)
  }

  func testEncodedValueCodableUsesPayloadObject() throws {
    let encoded = try BookishEncodedValue(encoding: Dimensions(width: 12, height: 20))
    let data = try JSONEncoder().encode(encoded)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(object["width"] as? Int, 12)
    XCTAssertEqual(object["height"] as? Int, 20)
    XCTAssertNil(object["payload"])

    let decoded = try JSONDecoder().decode(BookishEncodedValue.self, from: data)

    XCTAssertEqual(decoded, encoded)
  }

  func testRecordCodableRoundTrip() throws {
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "title": .string("Bookish"),
        "deleted": .tombstone,
      ]
    )

    let data = try JSONEncoder().encode(record)
    let decoded = try JSONDecoder().decode(BookishRecord.self, from: data)

    XCTAssertEqual(decoded, record)
  }
}

private struct Dimensions: Codable, Equatable {
  var width: Int
  var height: Int
}
