// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Identifies a Bookish catalogue record.
public struct BookishRecordID: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
  /// The stable raw identifier used by providers, storage, and interchange.
  public let rawValue: String

  /// Creates an identifier from an existing raw value.
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a new unique record identifier.
  public init() {
    self.rawValue = UUID().uuidString
  }

  /// A readable representation of the identifier.
  public var description: String {
    rawValue
  }
}
