// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Describes a service that identifies books from image data.
public protocol BookRecognizer: Sendable, Identifiable {
  /// The stable identifier used to select the recognizer.
  var id: String { get }

  /// The user-facing name of the recognizer.
  var label: String { get }

  /// A user-facing explanation of the recognizer's behavior.
  var description: String { get }

  /// Identifies the books shown in an image.
  func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate]
}
