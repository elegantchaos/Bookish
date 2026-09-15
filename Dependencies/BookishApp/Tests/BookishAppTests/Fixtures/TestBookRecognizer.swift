// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Foundation

/// A deterministic recognizer used by recognition-service tests.
struct TestBookRecognizer: BookRecognizer {
  /// The recognizer's stable identifier.
  let id: String

  /// The human-readable recognizer name.
  let label: String

  /// A short description of the recognizer.
  let description: String

  /// Whether this recognizer can run in the test scenario.
  let isSupported: Bool

  /// Creates a recognizer with the supplied availability.
  init(id: String, isSupported: Bool = true) {
    self.id = id
    label = id
    description = id
    self.isSupported = isSupported
  }

  /// Returns no candidates, as recognition results are not under test.
  func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    []
  }
}
