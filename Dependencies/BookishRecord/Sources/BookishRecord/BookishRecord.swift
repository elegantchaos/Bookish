// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A materialised Bookish catalogue record.
public struct BookishRecord: Codable, Equatable, Identifiable, Sendable {
  /// The record's stable identity.
  public var id: BookishRecordID

  /// The application-level kind of record.
  public var kind: String

  /// The record's materialised properties.
  public var properties: [String: BookishRecordValue]

  /// Creates a materialised record.
  public init(
    id: BookishRecordID = BookishRecordID(),
    kind: String,
    properties: [String: BookishRecordValue] = [:]
  ) {
    self.id = id
    self.kind = kind
    self.properties = properties
  }

  /// Reads a string property by key.
  public func string(_ key: String) -> String? {
    properties[key]?.stringValue
  }

  /// Reads an integer property by key.
  public func integer(_ key: String) -> Int? {
    properties[key]?.integerValue
  }

  /// Reads a boolean property by key.
  public func bool(_ key: String) -> Bool? {
    properties[key]?.boolValue
  }

  /// Reads a list property by key.
  public func list(_ key: String) -> [BookishRecordValue]? {
    properties[key]?.listValue
  }

  /// Reads a string-list property by key.
  public func strings(_ key: String) -> [String]? {
    properties[key]?.listValue?.compactMap(\.stringValue)
  }

  /// Reads a record link property by key.
  public func record(_ key: String) -> BookishRecordID? {
    properties[key]?.recordValue
  }

  /// Reads an encoded Codable payload property by key.
  public func encoded<Value: Decodable>(_ key: String, as type: Value.Type = Value.self) -> Value? {
    try? properties[key]?.encodedValue?.decode(type)
  }

}
