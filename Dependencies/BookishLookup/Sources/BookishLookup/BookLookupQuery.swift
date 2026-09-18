// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Describes the text used to find book metadata.
public struct BookLookupQuery: Codable, Equatable, Hashable, Sendable {
  /// The ISBN, title, author, or other text supplied for a lookup.
  public let text: String

  /// Creates a query after removing incidental whitespace.
  public init(_ text: String) {
    self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
