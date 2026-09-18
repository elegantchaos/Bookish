// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecognition
import Foundation

/// A deterministic recognition provider used by recognition-service tests.
struct TestBookRecognitionProvider: BookRecognitionProvider {
  /// The recognition provider's stable identifier.
  let id: BookRecognitionProviderID

  /// The human-readable recognition provider name.
  let label: String

  /// A short description of the recognition provider.
  let description: String

  /// Whether this recognition provider can run in the test scenario.
  let isSupported: Bool

  /// Creates a recognition provider with the supplied availability.
  init(id: BookRecognitionProviderID, isSupported: Bool = true) {
    self.id = id
    label = id.rawValue
    description = id.rawValue
    self.isSupported = isSupported
  }

  /// Returns no candidates, as recognition results are not under test.
  func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    []
  }
}
