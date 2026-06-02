// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Identifies a Bookish interchange file format and version.
public struct BookishInterchangeFormat: Codable, Equatable, Sendable {
  /// The Bookish records interchange format identifier.
  public static let records = BookishInterchangeFormat(
    id: "com.elegantchaos.bookish.records",
    version: 1
  )

  /// The format identifier.
  public var id: String

  /// The format version.
  public var version: Int

  /// Creates an interchange format marker.
  public init(id: String, version: Int) {
    self.id = id
    self.version = version
  }
}
