// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// An opaque JSON object payload encoded from a small Codable value.
public struct BookishEncodedValue: Codable, Equatable, Sendable {
  private var payload: [String: JSONPayloadValue]

  /// Decodes an opaque JSON object payload.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: JSONPayloadCodingKey.self)
    var payload: [String: JSONPayloadValue] = [:]
    for key in container.allKeys {
      payload[key.stringValue] = try container.decode(JSONPayloadValue.self, forKey: key)
    }

    self.payload = payload
  }

  /// Encodes this value as its opaque JSON object payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: JSONPayloadCodingKey.self)
    for (key, value) in payload {
      try container.encode(value, forKey: JSONPayloadCodingKey(stringValue: key))
    }
  }

  /// Encodes a Codable value into an opaque JSON object payload.
  public init<Value: Encodable>(encoding value: Value, encoder: JSONEncoder = JSONEncoder()) throws
  {
    let data = try encoder.encode(value)
    let json = try JSONSerialization.jsonObject(with: data)
    guard let payload = json as? [String: Any] else {
      throw BookishEncodedValueError.unsupportedTopLevelValue
    }

    self.payload = try payload.mapValues { try JSONPayloadValue(json: $0) }
  }

  /// Creates an opaque payload from a JSON object.
  public init(jsonObject: [String: Any]) throws {
    self.payload = try jsonObject.mapValues { try JSONPayloadValue(json: $0) }
  }

  /// Decodes this opaque JSON object payload into a Codable value.
  public func decode<Value: Decodable>(
    _ type: Value.Type,
    decoder: JSONDecoder = JSONDecoder()
  ) throws -> Value {
    let data = try JSONSerialization.data(withJSONObject: jsonObject())
    return try decoder.decode(type, from: data)
  }

  /// Returns this value as a JSONSerialization-compatible object.
  public func jsonObject() throws -> [String: Any] {
    try payload.mapValues { try $0.jsonObject() }
  }

  /// Returns the top-level payload keys.
  public var keys: [String] {
    Array(payload.keys)
  }
}

/// Errors raised while converting encoded JSON payloads.
public enum BookishEncodedValueError: Error, Equatable {
  /// Encoded payloads must be top-level JSON objects.
  case unsupportedTopLevelValue

  /// A value cannot be represented as JSON.
  case unsupportedValue(String)
}

private indirect enum JSONPayloadValue: Codable, Equatable, Sendable {
  case null
  case string(String)
  case integer(Int)
  case double(Double)
  case bool(Bool)
  case list([JSONPayloadValue])
  case object([String: JSONPayloadValue])

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Int.self) {
      self = .integer(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([JSONPayloadValue].self) {
      self = .list(value)
    } else if let value = try? container.decode([String: JSONPayloadValue].self) {
      self = .object(value)
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unsupported JSON payload value."
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .null:
      try container.encodeNil()

    case .string(let value):
      try container.encode(value)

    case .integer(let value):
      try container.encode(value)

    case .double(let value):
      try container.encode(value)

    case .bool(let value):
      try container.encode(value)

    case .list(let values):
      try container.encode(values)

    case .object(let values):
      try container.encode(values)
    }
  }

  init(json: Any) throws {
    switch json {
    case is NSNull:
      self = .null

    case let value as String:
      self = .string(value)

    case let value as NSNumber:
      if CFGetTypeID(value) == CFBooleanGetTypeID() {
        self = .bool(value.boolValue)
      } else {
        let double = value.doubleValue
        if double.rounded() == double {
          self = .integer(value.intValue)
        } else {
          self = .double(double)
        }
      }

    case let value as Bool:
      self = .bool(value)

    case let value as [Any]:
      self = .list(try value.map { try Self(json: $0) })

    case let value as [String: Any]:
      self = .object(try value.mapValues { try Self(json: $0) })

    default:
      throw BookishEncodedValueError.unsupportedValue(String(describing: json))
    }
  }

  func jsonObject() throws -> Any {
    switch self {
    case .null:
      return NSNull()

    case .string(let value):
      return value

    case .integer(let value):
      return value

    case .double(let value):
      return value

    case .bool(let value):
      return value

    case .list(let values):
      return try values.map { try $0.jsonObject() }

    case .object(let values):
      return try values.mapValues { try $0.jsonObject() }
    }
  }
}

private struct JSONPayloadCodingKey: CodingKey {
  var stringValue: String

  var intValue: Int? {
    nil
  }

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  init?(intValue: Int) {
    nil
  }
}
