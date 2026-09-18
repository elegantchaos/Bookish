// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Describes a service that identifies books from image data.
public protocol BookRecognitionProvider: Sendable, Identifiable {
  /// The stable identifier used to select the recognition provider.
  var id: BookRecognitionProviderID { get }

  /// The user-facing name of the recognition provider.
  var label: String { get }

  /// A user-facing explanation of the recognition provider's behavior.
  var description: String { get }

  /// Whether the recognition provider can run on the current device.
  var isSupported: Bool { get }

  /// Identifies the books shown in an image.
  func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate]
}

extension BookRecognitionProvider {
  /// Indicates that recognition providers without platform requirements are supported.
  public var isSupported: Bool { true }
}
