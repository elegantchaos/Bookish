// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A URL stored as an encoded Bookish record value.
public struct BookishRecordURL: Codable, Equatable, Sendable {
  /// The stable kind hint used for encoded URL values.
  public static let kind = "url"

  /// The represented URL.
  public var url: URL

  /// Creates an encoded URL payload.
  public init(url: URL) {
    self.url = url
  }
}
