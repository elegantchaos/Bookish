// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A date stored as an encoded Bookish record value.
public struct BookishRecordDate: Codable, Equatable, Sendable {
  /// The stable kind hint used for encoded date values.
  public static let kind = "date"

  /// The represented date.
  public var date: Date

  /// Creates an encoded date payload.
  public init(date: Date) {
    self.date = date
  }
}
