// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// Resolves presentation metadata for record property keys.
public protocol PresentationResolver: Sendable {
  /// Returns the metadata to use when displaying a property key.
  func presentation(for key: String) -> BookishPropertyPresentation?
}

/// Resolves property metadata from presentation records ordered by specificity.
public struct CascadingPresentationResolver: PresentationResolver, Equatable {
  /// Presentation records ordered from most to least specific.
  public let presentationRecords: [BookishRecord]

  /// Creates a resolver from presentation records ordered by specificity.
  public init(presentationRecords: [BookishRecord] = []) {
    self.presentationRecords = presentationRecords
  }

  /// Returns the first presentation metadata matching a property key.
  public func presentation(for key: String) -> BookishPropertyPresentation? {
    presentationRecords.lazy.compactMap {
      $0.encoded(key, as: BookishPropertyPresentation.self)
    }.first
  }
}
