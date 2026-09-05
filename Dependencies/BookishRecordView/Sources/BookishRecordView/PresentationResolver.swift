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

  /// Creates a resolver from a layout and presentation records ordered from kind-specific to generic.
  public init(layout: BookishRecord? = nil, presentationRecords: [BookishRecord] = []) {
    if let presentationID = layout?.record(BookishRecordKey.presentation),
      let presentation = presentationRecords.first(where: { $0.id == presentationID })
    {
      self.presentationRecords =
        [presentation] + presentationRecords.filter { $0.id != presentationID }
    } else {
      self.presentationRecords = presentationRecords
    }
  }

  /// Returns metadata merged from generic through the most-specific matching presentation.
  public func presentation(for key: String) -> BookishPropertyPresentation? {
    let presentations = presentationRecords.compactMap {
      $0.encoded(key, as: BookishPropertyPresentation.self)
    }
    guard presentations.isEmpty == false else {
      return nil
    }

    return presentations.reversed().reduce(into: BookishPropertyPresentation()) { result, next in
      if let icon = next.icon {
        result.icon = icon
      }
      if let label = next.label {
        result.label = label
      }
      if let viewer = next.viewer {
        result.viewer = viewer
      }
      if let editor = next.editor {
        result.editor = editor
      }
      if let alwaysShowViewer = next.alwaysShowViewer {
        result.alwaysShowViewer = alwaysShowViewer
      }
    }
  }
}
