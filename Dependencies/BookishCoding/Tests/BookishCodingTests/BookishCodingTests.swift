import BookishRecord
import Foundation
import XCTest

@testable import BookishCoding

final class BookishCodingTests: XCTestCase {
  func testCanonicalRoundTrip() throws {
    let file = BookishInterchangeFile(
      root: BookishRecordID("book-1"),
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: [
            "title": .string("Snow Crash"),
            "pages": .integer(470),
            "author": .record(BookishRecordID("person-1")),
            "deleted": .tombstone,
          ]
        )
      ]
    )

    let codec = BookishInterchangeCodec()
    let data = try codec.encode(file)
    let decoded = try codec.decode(data)

    XCTAssertEqual(decoded, file)
  }

  func testCompactDecodeSupportsPrimitiveValuesAndRecordLinks() throws {
    let json = """
      {
        "format": { "id": "com.elegantchaos.bookish.records", "version": 1 },
        "records": [
          {
            "id": "book-1",
            "kind": "book",
            "title": "Snow Crash",
            "pages": 470,
            "owned": true,
            "rating": 4.5,
            "author": "@person-1"
          }
        ]
      }
      """

    let decoded = try BookishInterchangeCodec().decode(Data(json.utf8))
    let record = try XCTUnwrap(decoded.records.first)

    XCTAssertEqual(record.string("title"), "Snow Crash")
    XCTAssertEqual(record.integer("pages"), 470)
    XCTAssertEqual(record.properties["owned"], .bool(true))
    XCTAssertEqual(record.properties["rating"], .double(4.5))
    XCTAssertEqual(record.record("author"), BookishRecordID("person-1"))
  }

  func testCompactEncodeCanEmitRecordLinkShorthand() throws {
    let file = BookishInterchangeFile(
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: ["author": .record(BookishRecordID("person-1"))]
        )
      ]
    )

    let data = try BookishInterchangeCodec(recordLinkEncoding: .shorthand).encode(file)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let records = try XCTUnwrap(object?["records"] as? [[String: Any]])

    XCTAssertEqual(records.first?["author"] as? String, "@person-1")
  }

  func testSchemaOverridesReservedKeys() throws {
    let json = """
      {
        "schema": {
          "idKey": "_id",
          "kindKey": "_kind",
          "defaultKind": "book",
          "rvKey": "_value"
        },
        "root": { "_value": "record", "id": "book-1" },
        "records": [
          {
            "_id": "book-1",
            "title": "Snow Crash",
            "author": { "_value": "record", "id": "person-1" }
          }
        ]
      }
      """

    let decoded = try BookishInterchangeCodec().decode(Data(json.utf8))
    let record = try XCTUnwrap(decoded.records.first)

    XCTAssertEqual(decoded.schema.idKey, "_id")
    XCTAssertEqual(decoded.root, BookishRecordID("book-1"))
    XCTAssertEqual(record.kind, "book")
    XCTAssertEqual(record.record("author"), BookishRecordID("person-1"))

    let encoded = try BookishInterchangeCodec().encode(decoded)
    let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let root = try XCTUnwrap(object?["root"] as? [String: Any])

    XCTAssertEqual(root["_value"] as? String, "record")
  }

  func testStrictModeRejectsInvalidShorthand() throws {
    let json = """
      {
        "records": [
          {
            "id": "book-1",
            "kind": "book",
            "author": "@not valid"
          }
        ]
      }
      """

    let codec = BookishInterchangeCodec(invalidShorthandHandling: .error)

    XCTAssertThrowsError(try codec.decode(Data(json.utf8))) { error in
      XCTAssertEqual(error as? BookishCodingError, .invalidRecordReference("@not valid"))
    }
  }

  func testRejectsMalformedExplicitRecordReference() throws {
    let json = """
      {
        "records": [
          {
            "id": "book-1",
            "kind": "book",
            "author": { "_rvtype": "record" }
          }
        ]
      }
      """

    XCTAssertThrowsError(try BookishInterchangeCodec().decode(Data(json.utf8))) { error in
      XCTAssertEqual(error as? BookishCodingError, .missingRecordReferenceID)
    }
  }

  func testShorthandEncodeRejectsInvalidRecordID() throws {
    let file = BookishInterchangeFile(
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: ["author": .record(BookishRecordID("not valid"))]
        )
      ]
    )

    let codec = BookishInterchangeCodec(recordLinkEncoding: .shorthand)

    XCTAssertThrowsError(try codec.encode(file)) { error in
      XCTAssertEqual(error as? BookishCodingError, .invalidRecordID("not valid"))
    }
  }
}
