// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A JSON value embedded as an opaque property payload.
public indirect enum BookishEncodedValue: Codable, Equatable, Sendable {
  /// A null value.
  case null

  /// A string value.
  case string(String)

  /// A whole-number value.
  case integer(Int)

  /// A floating-point value.
  case double(Double)

  /// A boolean value.
  case bool(Bool)

  /// An ordered JSON array.
  case list([BookishEncodedValue])

  /// A JSON object.
  case object([String: BookishEncodedValue])
}

extension BookishEncodedValue {
  /// Encodes a Codable value into a JSON payload.
  public init<Value: Encodable>(encoding value: Value, encoder: JSONEncoder = JSONEncoder()) throws
  {
    let data = try encoder.encode(value)
    let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    self = try Self(json: json)
  }

  /// Decodes this JSON payload into a Codable value.
  public func decode<Value: Decodable>(
    _ type: Value.Type,
    decoder: JSONDecoder = JSONDecoder()
  ) throws -> Value {
    let json = try jsonObject()
    let data = try JSONSerialization.data(withJSONObject: json, options: [.fragmentsAllowed])
    return try decoder.decode(type, from: data)
  }

  /// Creates a payload from a JSONSerialization-compatible value.
  public init(json: Any) throws {
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

  /// Returns a JSONSerialization-compatible value.
  public func jsonObject() throws -> Any {
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

/// Errors raised while converting encoded JSON payloads.
public enum BookishEncodedValueError: Error, Equatable {
  /// A value cannot be represented as JSON.
  case unsupportedValue(String)
}
