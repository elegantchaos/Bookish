import Foundation
import Testing

@testable import BookishRecord

struct BookishRecordTests {
  @Test
  func standardKindsAndKeysHaveStableValues() {
    #expect(BookishRecordKind.book == "book")
    #expect(BookishRecordKind.person == "person")
    #expect(BookishRecordKind.organisation == "organisation")
    #expect(BookishRecordKey.authors == "authors")
    #expect(BookishRecordKey.series == "series")
    #expect(BookishRecordKey.seriesPosition == "seriesPosition")
    #expect(BookishRecordKey.isbn == "isbn")
    #expect(BookishRecordKey.types == "types")
    #expect(BookishRecordKey.allTypes == "*")
  }

  @Test

  func recordConstructionAndConvenienceReaders() {
    let authorID = BookishRecordID("person-1")
    let record = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [
        "title": .string("Bookish"),
        "pages": .integer(320),
        "authors": .list([.record(authorID)]),
        "types": .list([.string("book")]),
        "primaryAuthor": .record(authorID),
      ]
    )

    #expect(record.id.rawValue == "book-1")
    #expect(record.kind == "book")
    #expect(record.string("title") == "Bookish")
    #expect(record.integer("pages") == 320)
    #expect(record.record("primaryAuthor") == authorID)
    #expect(record.list("authors") == [.record(authorID)])
    #expect(record.strings("types") == ["book"])
  }

  @Test

  func recordValueSupportsNestedListsAndEncodedValues() throws {
    let dimensions = try BookishEncodedValue(encoding: Dimensions(width: 12, height: 20))
    let value = BookishRecordValue.list([
      .record(BookishRecordID("person-1")),
      .encoded(dimensions),
    ])

    #expect(
      value
        == .list([
          .record(BookishRecordID("person-1")),
          .encoded(dimensions),
        ]))
  }

  @Test

  func recordCanReadEncodedPayloads() throws {
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

    #expect(inferred == dimensions)
    #expect(record.encoded("dimensions", as: Dimensions.self) == dimensions)
    #expect(record.encoded("missing", as: Dimensions.self) == nil)
    #expect(record.encoded("title", as: Dimensions.self) == nil)
  }

  @Test

  func encodedValueCanRoundTripCodablePayload() throws {
    let dimensions = Dimensions(width: 12, height: 20)
    let encoded = try BookishEncodedValue(encoding: dimensions)
    let decoded = try encoded.decode(Dimensions.self)

    #expect(decoded == dimensions)
  }

  @Test

  func encodedValueCodableUsesPayloadObject() throws {
    let encoded = try BookishEncodedValue(encoding: Dimensions(width: 12, height: 20))
    let data = try JSONEncoder().encode(encoded)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(object["width"] as? Int == 12)
    #expect(object["height"] as? Int == 20)
    #expect(object["payload"] == nil)

    let decoded = try JSONDecoder().decode(BookishEncodedValue.self, from: data)

    #expect(decoded == encoded)
  }

  @Test

  func recordCodableRoundTrip() throws {
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

    #expect(decoded == record)
  }
}

private struct Dimensions: Codable, Equatable {
  var width: Int
  var height: Int
}
