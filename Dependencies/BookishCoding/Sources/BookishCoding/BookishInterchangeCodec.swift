// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// Encodes and decodes Bookish materialised-record interchange JSON.
public struct BookishInterchangeCodec: Sendable {
  /// Controls whether record links are encoded in canonical or shorthand form.
  public enum RecordLinkEncoding: Sendable {
    /// Encode record links as explicit record value objects.
    case canonical

    /// Encode record links as `@record-id` strings.
    case shorthand
  }

  /// Controls how invalid strings starting with `@` are handled while decoding.
  public enum InvalidShorthandHandling: Sendable {
    /// Treat invalid shorthand-like strings as normal strings.
    case asString

    /// Reject invalid shorthand-like strings.
    case error
  }

  /// The encoding style to use for record links.
  public var recordLinkEncoding: RecordLinkEncoding

  /// How invalid shorthand-like strings should be decoded.
  public var invalidShorthandHandling: InvalidShorthandHandling

  /// Creates an interchange codec.
  public init(
    recordLinkEncoding: RecordLinkEncoding = .canonical,
    invalidShorthandHandling: InvalidShorthandHandling = .asString
  ) {
    self.recordLinkEncoding = recordLinkEncoding
    self.invalidShorthandHandling = invalidShorthandHandling
  }

  /// Encodes an interchange file as JSON data.
  public func encode(_ file: BookishInterchangeFile) throws -> Data {
    var dictionary: [String: Any] = [
      "format": try encodeCodable(file.format),
      "records": try file.records.map { try encodeRecord($0, schema: file.schema) },
    ]

    if file.schema != .default {
      dictionary["schema"] = try encodeCodable(file.schema)
    }

    if let root = file.root {
      dictionary["root"] = try encodeRecordReference(root, schema: file.schema)
    }

    return try JSONSerialization.data(
      withJSONObject: dictionary,
      options: [.prettyPrinted, .sortedKeys]
    )
  }

  /// Decodes an interchange file from JSON data.
  public func decode(_ data: Data) throws -> BookishInterchangeFile {
    guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw BookishCodingError.invalidFile
    }

    let format: BookishInterchangeFormat
    if let formatDictionary = dictionary["format"] as? [String: Any] {
      format = try decodeCodable(BookishInterchangeFormat.self, from: formatDictionary)
    } else {
      format = .records
    }

    let schema: BookishInterchangeSchema
    if let schemaDictionary = dictionary["schema"] as? [String: Any] {
      schema = try decodeCodable(BookishInterchangeSchema.self, from: schemaDictionary)
    } else {
      schema = .default
    }

    let root = try decodeRoot(dictionary["root"], schema: schema)

    guard let rawRecords = dictionary["records"] as? [[String: Any]] else {
      throw BookishCodingError.missingRecords
    }

    let records = try rawRecords.map { try decodeRecord($0, schema: schema) }
    return BookishInterchangeFile(format: format, schema: schema, root: root, records: records)
  }

  private func encodeRecord(_ record: BookishRecord, schema: BookishInterchangeSchema) throws
    -> [String: Any]
  {
    var dictionary = try record.properties.mapValues { try encodeValue($0, schema: schema) }
    dictionary[schema.idKey] = record.id.rawValue
    dictionary[schema.kindKey] = record.kind
    return dictionary
  }

  private func decodeRecord(_ dictionary: [String: Any], schema: BookishInterchangeSchema) throws
    -> BookishRecord
  {
    guard let rawID = dictionary[schema.idKey] as? String else {
      throw BookishCodingError.missingRecordID
    }

    try validateRecordID(rawID)
    let kind = dictionary[schema.kindKey] as? String ?? schema.defaultKind
    var properties: [String: BookishRecordValue] = [:]

    for (key, rawValue) in dictionary {
      guard key != schema.idKey, key != schema.kindKey else {
        continue
      }

      properties[key] = try decodeValue(rawValue, schema: schema)
    }

    return BookishRecord(id: BookishRecordID(rawID), kind: kind, properties: properties)
  }

  private func encodeValue(_ value: BookishRecordValue, schema: BookishInterchangeSchema) throws
    -> Any
  {
    switch value {
    case .string(let value):
      return value

    case .integer(let value):
      return value

    case .double(let value):
      return value

    case .bool(let value):
      return value

    case .date(let value):
      return [
        schema.rvKey: "date",
        "value": Self.encodeDate(value),
      ]

    case .record(let value):
      return try encodeRecordReference(value, schema: schema)

    case .blob(let value):
      var dictionary: [String: Any] = [
        schema.rvKey: "blob",
        "id": value.id,
      ]
      dictionary["mediaType"] = value.mediaType
      dictionary["byteCount"] = value.byteCount
      dictionary["checksum"] = value.checksum
      dictionary["filename"] = value.filename
      return dictionary.compactMapValues { $0 }

    case .list(let values):
      return try values.map { try encodeValue($0, schema: schema) }

    case .object(let values):
      return try values.mapValues { try encodeValue($0, schema: schema) }

    case .tombstone:
      return [schema.rvKey: "tombstone"]

    case .deletion:
      return [schema.rvKey: "deletion"]

    case .conflict(let values):
      return [
        schema.rvKey: "conflict",
        "values": try values.map { try encodeValue($0, schema: schema) },
      ]
    }
  }

  private func encodeRecordReference(
    _ id: BookishRecordID,
    schema: BookishInterchangeSchema = .default
  ) throws -> Any {
    try validateRecordID(id.rawValue)

    switch recordLinkEncoding {
    case .canonical:
      return [
        schema.rvKey: "record",
        "id": id.rawValue,
      ]

    case .shorthand:
      return "@\(id.rawValue)"
    }
  }

  private func decodeValue(_ rawValue: Any, schema: BookishInterchangeSchema) throws
    -> BookishRecordValue
  {
    switch rawValue {
    case let value as String:
      return try decodeString(value)

    case let value as NSNumber:
      if CFGetTypeID(value) == CFBooleanGetTypeID() {
        return .bool(value.boolValue)
      }

      let double = value.doubleValue
      if double.rounded() == double {
        return .integer(value.intValue)
      }

      return .double(double)

    case let value as Bool:
      return .bool(value)

    case let value as [Any]:
      return .list(try value.map { try decodeValue($0, schema: schema) })

    case let value as [String: Any]:
      return try decodeObject(value, schema: schema)

    default:
      throw BookishCodingError.unsupportedValue(String(describing: rawValue))
    }
  }

  private func decodeString(_ value: String) throws -> BookishRecordValue {
    guard value.starts(with: "@") else {
      return .string(value)
    }

    let id = String(value.dropFirst())
    if Self.isValidRecordID(id) {
      return .record(BookishRecordID(id))
    }

    switch invalidShorthandHandling {
    case .asString:
      return .string(value)

    case .error:
      throw BookishCodingError.invalidRecordReference(value)
    }
  }

  private func decodeObject(_ dictionary: [String: Any], schema: BookishInterchangeSchema) throws
    -> BookishRecordValue
  {
    guard let kind = dictionary[schema.rvKey] as? String else {
      return .object(try dictionary.mapValues { try decodeValue($0, schema: schema) })
    }

    switch kind {
    case "record":
      guard let id = dictionary["id"] as? String else {
        throw BookishCodingError.missingRecordReferenceID
      }
      try validateRecordID(id)
      return .record(BookishRecordID(id))

    case "blob":
      guard let id = dictionary["id"] as? String else {
        throw BookishCodingError.missingBlobID
      }
      return .blob(
        BookishBlobReference(
          id: id,
          mediaType: dictionary["mediaType"] as? String,
          byteCount: dictionary["byteCount"] as? Int,
          checksum: dictionary["checksum"] as? String,
          filename: dictionary["filename"] as? String
        )
      )

    case "date":
      guard
        let string = dictionary["value"] as? String,
        let date = Self.decodeDate(string)
      else {
        throw BookishCodingError.invalidDate
      }
      return .date(date)

    case "tombstone":
      return .tombstone

    case "deletion":
      return .deletion

    case "conflict":
      guard let rawValues = dictionary["values"] as? [Any] else {
        throw BookishCodingError.invalidConflict
      }
      return .conflict(try rawValues.map { try decodeValue($0, schema: schema) })

    default:
      throw BookishCodingError.unknownRecordValueKind(kind)
    }
  }

  private func decodeRoot(_ rawValue: Any?, schema: BookishInterchangeSchema) throws
    -> BookishRecordID?
  {
    guard let rawValue else {
      return nil
    }

    switch rawValue {
    case let value as String:
      if value.starts(with: "@") {
        let id = String(value.dropFirst())
        try validateRecordID(id)
        return BookishRecordID(id)
      }

      try validateRecordID(value)
      return BookishRecordID(value)

    case let dictionary as [String: Any]:
      guard case .record(let id) = try decodeValue(dictionary, schema: schema) else {
        throw BookishCodingError.invalidRoot
      }
      return id

    default:
      throw BookishCodingError.invalidRoot
    }
  }

  private func validateRecordID(_ id: String) throws {
    guard Self.isValidRecordID(id) else {
      throw BookishCodingError.invalidRecordID(id)
    }
  }

  private func encodeCodable<Value: Encodable>(_ value: Value) throws -> Any {
    let data = try JSONEncoder().encode(value)
    return try JSONSerialization.jsonObject(with: data)
  }

  private func decodeCodable<Value: Decodable>(_ type: Value.Type, from dictionary: [String: Any])
    throws -> Value
  {
    let data = try JSONSerialization.data(withJSONObject: dictionary)
    return try JSONDecoder().decode(type, from: data)
  }

  private static func isValidRecordID(_ id: String) -> Bool {
    guard let first = id.first, first.isLetter || first.isNumber else {
      return false
    }

    return id.allSatisfy { character in
      character.isLetter || character.isNumber || character == "." || character == "_"
        || character == ":" || character == "-"
    }
  }

  private static func encodeDate(_ date: Date) -> String {
    dateFormatter().string(from: date)
  }

  private static func decodeDate(_ string: String) -> Date? {
    dateFormatter().date(from: string)
  }

  private static func dateFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }
}
