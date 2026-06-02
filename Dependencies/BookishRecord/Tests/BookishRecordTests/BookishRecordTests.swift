import Foundation
import XCTest

@testable import BookishRecord

final class BookishRecordTests: XCTestCase {
  func testRecordConstructionAndConvenienceReaders() {
    let authorID = BookishRecordID("person-1")
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "title": .string("Prototype"),
        "pages": .integer(320),
        "authors": .list([.record(authorID)]),
        "primaryAuthor": .record(authorID),
      ]
    )

    XCTAssertEqual(record.id.rawValue, "book-1")
    XCTAssertEqual(record.kind, "book")
    XCTAssertEqual(record.string("title"), "Prototype")
    XCTAssertEqual(record.integer("pages"), 320)
    XCTAssertEqual(record.record("primaryAuthor"), authorID)
    XCTAssertEqual(record.list("authors"), [.record(authorID)])
  }

  func testRecordValueSupportsNestedListsAndEncodedValues() {
    let value = BookishRecordValue.list([
      .record(BookishRecordID("person-1")),
      .encoded([
        "height": .double(20.5),
        "width": .integer(12),
      ]),
    ])

    XCTAssertEqual(
      value,
      .list([
        .record(BookishRecordID("person-1")),
        .encoded([
          "height": .double(20.5),
          "width": .integer(12),
        ]),
      ])
    )
  }

  func testEncodedValueCanRoundTripCodablePayload() throws {
    let dimensions = Dimensions(width: 12, height: 20)
    let encoded = try BookishEncodedValue(encoding: dimensions)
    let decoded = try encoded.decode(Dimensions.self)

    XCTAssertEqual(decoded, dimensions)
  }

  func testRecordCodableRoundTrip() throws {
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "title": .string("Prototype"),
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
