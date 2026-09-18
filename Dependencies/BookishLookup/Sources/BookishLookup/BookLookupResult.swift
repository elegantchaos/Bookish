// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Collects candidates and individual provider failures from one lookup.
public struct BookLookupResult: Sendable {
  /// The candidates returned by providers that completed successfully.
  public let candidates: [BookLookupCandidate]

  /// The failures reported by providers that could not complete.
  public let failures: [BookLookupFailure]

  /// Creates a result from completed provider work.
  public init(candidates: [BookLookupCandidate], failures: [BookLookupFailure]) {
    self.candidates = candidates
    self.failures = failures
  }
}
