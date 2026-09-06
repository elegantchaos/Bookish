// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI

/// Displays a record image thumbnail or an SF Symbol fallback with shared circular styling.
public struct BookishRecordThumbnail: View {
  private let url: URL?
  private let placeholderSystemImage: String

  @ScaledMetric(relativeTo: .headline) private var size = 40.0

  /// Creates a thumbnail from an optional remote image URL.
  public init(url: URL?, placeholderSystemImage: String) {
    self.url = url
    self.placeholderSystemImage = placeholderSystemImage
  }

  /// The image or fallback symbol constrained to a circular thumbnail.
  public var body: some View {
    Group {
      if let url {
        AsyncImage(url: url) { phase in
          if let image = phase.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            BookishRecordThumbnailPlaceholder(systemImage: placeholderSystemImage)
          }
        }
      } else {
        BookishRecordThumbnailPlaceholder(systemImage: placeholderSystemImage)
      }
    }
    .frame(width: size, height: size)
    .background(.quaternary, in: .circle)
    .clipShape(.circle)
    .accessibilityHidden(true)
  }
}

/// Displays the decorative SF Symbol used when a record has no thumbnail.
private struct BookishRecordThumbnailPlaceholder: View {
  private let systemImage: String

  /// Creates a fallback thumbnail icon.
  init(systemImage: String) {
    self.systemImage = systemImage
  }

  /// The decorative fallback icon.
  var body: some View {
    Image(systemName: systemImage)
      .imageScale(.large)
      .foregroundStyle(.secondary)
  }
}
