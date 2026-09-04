import BookishRecord
import Foundation
import Testing

@testable import BookishCoding

struct BookishCodingTests {
  @Test
  func dateValuesRoundTripAsTaggedEncodedValues() throws {
    let date = Date(timeIntervalSince1970: 1_704_067_200)
    var book = BookishRecord(id: BookishRecordID("book-1"), kind: "book")
    try book.setDate(date, for: BookishRecordKey.publishedDate)
    let file = BookishInterchangeFile(records: [book])

    let data = try BookishInterchangeCodec().encode(file)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let records = try #require(object?["records"] as? [[String: Any]])
    let encodedDate = try #require(records.first?[BookishRecordKey.publishedDate] as? [String: Any])

    #expect(encodedDate["®"] as? String == BookishRecordDate.kind)
    #expect(encodedDate["date"] is String)
    #expect(try BookishInterchangeCodec().decode(data) == file)
  }

  @Test
  func defaultSchemaUsesRegisteredSignRecordValueKey() {
    #expect(BookishInterchangeSchema.default.rvKey == "®")
    #expect(BookishInterchangeSchema.default.idKey == "ℹ")
    #expect(BookishInterchangeSchema.default.kindKey == "©")
  }

  @Test

  func canonicalRoundTrip() throws {
    let file = BookishInterchangeFile(
      root: BookishRecordID("book-1"),
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: [
            "name": .string("Snow Crash"),
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

    #expect(decoded == file)
  }

  @Test

  func compactDecodeSupportsPrimitiveValuesAndRecordLinks() throws {
    let json = """
      {
        "format": { "id": "com.elegantchaos.bookish.records", "version": 1 },
        "records": [
          {
            "ℹ": "book-1",
            "©": "book",
            "name": "Snow Crash",
            "pages": 470,
            "owned": true,
            "rating": 4.5,
            "author": "@person-1"
          }
        ]
      }
      """

    let decoded = try BookishInterchangeCodec().decode(Data(json.utf8))
    let record = try #require(decoded.records.first)

    #expect(record.string("name") == "Snow Crash")
    #expect(record.integer("pages") == 470)
    #expect(record.properties["owned"] == .bool(true))
    #expect(record.properties["rating"] == .double(4.5))
    #expect(record.record("author") == BookishRecordID("person-1"))
  }

  @Test

  func compactEncodeCanEmitRecordLinkShorthand() throws {
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
    let records = try #require(object?["records"] as? [[String: Any]])

    #expect(records.first?["author"] as? String == "@person-1")
  }

  @Test

  func encodedValueUsesRemainingKeysAsPayload() throws {
    let dimensionsPayload = try BookishEncodedValue(
      encoding: Dimensions(width: 12, height: 20, tags: ["hardback", "shelf"])
    )
    let file = BookishInterchangeFile(
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: [
            "dimensions": .encoded(dimensionsPayload)
          ]
        )
      ]
    )

    let data = try BookishInterchangeCodec().encode(file)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let records = try #require(object?["records"] as? [[String: Any]])
    let dimensions = try #require(records.first?["dimensions"] as? [String: Any])

    #expect(dimensions["®"] == nil)
    #expect(dimensions["width"] as? Int == 12)
    #expect(dimensions["height"] as? Int == 20)

    let decoded = try BookishInterchangeCodec().decode(data)

    #expect(decoded == file)
  }

  @Test
  func encodedPresentationValuesRoundTripAsUntaggedProperties() throws {
    let propertyPresentation = BookishPropertyPresentation(
      icon: "textformat",
      label: "Name",
      viewer: "text"
    )
    let file = BookishInterchangeFile(
      records: [
        BookishRecord(
          id: BookishRecordID("presentation.type.*"),
          kind: BookishRecordKind.presentation,
          properties: [
            BookishRecordKey.name: .encoded(try BookishEncodedValue(encoding: propertyPresentation))
          ]
        )
      ]
    )

    let data = try BookishInterchangeCodec().encode(file)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let records = try #require(object?["records"] as? [[String: Any]])
    let presentation = try #require(records.first?[BookishRecordKey.name] as? [String: Any])

    #expect(presentation["®"] == nil)
    #expect(presentation["icon"] as? String == "textformat")
    #expect(try BookishInterchangeCodec().decode(data) == file)
  }

  @Test
  func unknownValueKindsRoundTripAsTaggedEncodedValues() throws {
    let json = """
      { "records": [{ "ℹ": "presentation.type.*", "©": "presentation", "name": {
        "®": "com.elegantchaos.bookish.property-presentation", "icon": "textformat"
      }}] }
      """

    let decoded = try BookishInterchangeCodec().decode(Data(json.utf8))
    let value = try #require(decoded.records.first?.properties["name"])

    #expect(value.encodedKind == "com.elegantchaos.bookish.property-presentation")
    #expect(try BookishInterchangeCodec().encode(decoded).isEmpty == false)
  }

  @Test
  func encodedValuesRejectTheActiveRecordValueKeyAsPayload() throws {
    let file = BookishInterchangeFile(
      records: [
        BookishRecord(
          id: BookishRecordID("book-1"),
          kind: "book",
          properties: ["value": .encoded(try BookishEncodedValue(jsonObject: ["®": "value"]))]
        )
      ]
    )

    #expect(throws: BookishCodingError.reservedRecordValueKey("®")) {
      try BookishInterchangeCodec().encode(file)
    }
  }

  @Test

  func schemaOverridesReservedKeys() throws {
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
            "name": "Snow Crash",
            "author": { "_value": "record", "id": "person-1" }
          }
        ]
      }
      """

    let decoded = try BookishInterchangeCodec().decode(Data(json.utf8))
    let record = try #require(decoded.records.first)

    #expect(decoded.schema.idKey == "_id")
    #expect(decoded.root == BookishRecordID("book-1"))
    #expect(record.kind == "book")
    #expect(record.record("author") == BookishRecordID("person-1"))

    let encoded = try BookishInterchangeCodec().encode(decoded)
    let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let root = try #require(object?["root"] as? [String: Any])

    #expect(root["_value"] as? String == "record")
  }

  @Test

  func strictModeRejectsInvalidShorthand() throws {
    let json = """
      {
        "records": [
          {
            "ℹ": "book-1",
            "©": "book",
            "author": "@not valid"
          }
        ]
      }
      """

    let codec = BookishInterchangeCodec(invalidShorthandHandling: .error)

    #expect(throws: BookishCodingError.invalidRecordReference("@not valid")) {
      try codec.decode(Data(json.utf8))
    }
  }

  @Test

  func rejectsMalformedExplicitRecordReference() throws {
    let json = """
      {
        "records": [
          {
            "ℹ": "book-1",
            "©": "book",
            "author": { "®": "record" }
          }
        ]
      }
      """

    #expect(throws: BookishCodingError.missingRecordReferenceID) {
      try BookishInterchangeCodec().decode(Data(json.utf8))
    }
  }

  @Test

  func untaggedObjectPropertyValuesDecodeAsEncodedValues() throws {
    let json = """
      {
        "records": [
          {
            "ℹ": "book-1",
            "©": "book",
            "dimensions": { "width": 12, "height": 20 }
          }
        ]
      }
      """

    let file = try BookishInterchangeCodec().decode(Data(json.utf8))
    #expect(
      file.records.first?.properties["dimensions"]?.encodedValue?.keys.sorted() == [
        "height", "width",
      ])
  }

  @Test

  func shorthandEncodeRejectsInvalidRecordID() throws {
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

    #expect(throws: BookishCodingError.invalidRecordID("not valid")) {
      try codec.encode(file)
    }
  }
}

private struct Dimensions: Codable, Equatable {
  var width: Int
  var height: Int
  var tags: [String]
}
