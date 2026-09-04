// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Defines reserved field names used by Bookish JSON interchange.
public struct BookishInterchangeSchema: Codable, Equatable, Sendable {
  /// The default interchange schema.
  public static let `default` = BookishInterchangeSchema()

  /// The record field that stores the record identifier.
  public var idKey: String

  /// The record field that stores the application-level record kind.
  public var kindKey: String

  /// The kind to use when a record omits `kindKey`.
  public var defaultKind: String

  /// The object field that marks an explicitly typed record value.
  public var rvKey: String

  /// Creates an interchange schema.
  public init(
    idKey: String = "ℹ",
    kindKey: String = "©",
    defaultKind: String = "record",
    rvKey: String = "®"
  ) {
    self.idKey = idKey
    self.kindKey = kindKey
    self.defaultKind = defaultKind
    self.rvKey = rvKey
  }

  /// Decodes a schema, using default values for missing fields.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.idKey = try container.decodeIfPresent(String.self, forKey: .idKey) ?? "ℹ"
    self.kindKey = try container.decodeIfPresent(String.self, forKey: .kindKey) ?? "©"
    self.defaultKind = try container.decodeIfPresent(String.self, forKey: .defaultKind) ?? "record"
    self.rvKey = try container.decodeIfPresent(String.self, forKey: .rvKey) ?? "®"
  }
}
