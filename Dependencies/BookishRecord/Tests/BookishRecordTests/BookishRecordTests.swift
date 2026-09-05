import Foundation
import Testing

@testable import BookishRecord

struct BookishRecordTests {
  @Test
  func datePropertiesUseEncodedDateValues() throws {
    let date = Date(timeIntervalSince1970: 1_704_067_200)
    var record = BookishRecord(kind: "book")

    try record.setDate(date, for: BookishRecordKey.publishedDate)

    #expect(record.date(BookishRecordKey.publishedDate) == date)
    #expect(
      record.properties[BookishRecordKey.publishedDate]?.encodedKind == BookishRecordDate.kind)
    #expect(
      try record.properties[BookishRecordKey.publishedDate]?.encodedValue?.decode(
        BookishRecordDate.self
      ).date
        == date)
  }

  @Test
  func encodedValuesUseTheBookishDateCodingStrategy() throws {
    let value = DatedPayload(date: Date(timeIntervalSince1970: 0))
    let encoded = try BookishEncodedValue(encoding: value)

    #expect(try encoded.jsonObject()["date"] as? String == "1970-01-01T00:00:00Z")
    #expect(try encoded.decode(DatedPayload.self) == value)
  }

  @Test
  func standardKindsAndKeysHaveStableValues() {
    #expect(BookishRecordKind.book == "book")
    #expect(BookishRecordKind.person == "person")
    #expect(BookishRecordKind.organisation == "organisation")
    #expect(BookishRecordKey.name == "name")
    #expect(BookishRecordKey.authors == "authors")
    #expect(BookishRecordKey.series == "series")
    #expect(BookishRecordKey.seriesPosition == "seriesPosition")
    #expect(BookishRecordKey.isbn == "isbn")
    #expect(BookishRecordKey.addedDate == "added")
    #expect(BookishRecordKey.modifiedDate == "modified")
    #expect(BookishRecordKey.publishedDate == "published")
    #expect(BookishRecordKey.originalData == "originalData")
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
        "name": .string("Bookish"),
        "pages": .integer(320),
        "authors": .list([.record(authorID)]),
        "types": .list([.string("book")]),
        "primaryAuthor": .record(authorID),
      ]
    )

    #expect(record.id.rawValue == "book-1")
    #expect(record.kind == "book")
    #expect(record.string("name") == "Bookish")
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
        "name": .string("Bookish"),
      ]
    )

    let inferred: Dimensions? = record.encoded("dimensions")

    #expect(inferred == dimensions)
    #expect(record.encoded("dimensions", as: Dimensions.self) == dimensions)
    #expect(record.encoded("missing", as: Dimensions.self) == nil)
    #expect(record.encoded("name", as: Dimensions.self) == nil)
  }

  @Test
  func recordDecodesPropertyPresentation() throws {
    let titlePresentation = BookishPropertyPresentation(icon: "textformat", label: "Title")
    let record = BookishRecord(
      kind: BookishRecordKind.presentation,
      properties: [
        BookishRecordKey.name: .encoded(try BookishEncodedValue(encoding: titlePresentation))
      ]
    )

    #expect(
      record.encoded(BookishRecordKey.name, as: BookishPropertyPresentation.self)
        == titlePresentation)
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
        "name": .string("Bookish"),
        "deleted": .tombstone,
      ]
    )

    let data = try JSONEncoder().encode(record)
    let decoded = try JSONDecoder().decode(BookishRecord.self, from: data)

    #expect(decoded == record)
  }
}

private struct DatedPayload: Codable, Equatable {
  var date: Date
}

private struct Dimensions: Codable, Equatable {
  var width: Int
  var height: Int
}
