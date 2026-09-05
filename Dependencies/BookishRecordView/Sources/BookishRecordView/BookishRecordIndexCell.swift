// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays a record as a thumbnail and name in a browser index.
public struct BookishRecordIndexCell: View {
  private let presentation: BookishRecordPresentation
  private let placeholderSystemImage: String

  /// Creates an index row using the record's configured header thumbnail.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    placeholderSystemImage: String,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver()
  ) {
    self.presentation = BookishRecordPresentation(
      record: record, layout: layout, presentationResolver: presentationResolver)
    self.placeholderSystemImage = placeholderSystemImage
  }

  /// The visual representation of the indexed record.
  public var body: some View {
    HStack(spacing: 10) {
      BookishRecordIndexThumbnail(
        url: presentation.header.thumbnailURL,
        placeholderSystemImage: placeholderSystemImage)

      Text(presentation.name)
        .font(.headline)
        .lineLimit(1)
        .truncationMode(.tail)
        .help(presentation.name)

      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}

/// Displays an image thumbnail or a configured SF Symbol fallback for an index row.
private struct BookishRecordIndexThumbnail: View {
  private let url: URL?
  private let placeholderSystemImage: String

  @ScaledMetric(relativeTo: .headline) private var size = 40.0

  /// Creates a thumbnail from an optional remote image URL.
  init(url: URL?, placeholderSystemImage: String) {
    self.url = url
    self.placeholderSystemImage = placeholderSystemImage
  }

  /// The image or fallback symbol constrained to a square thumbnail.
  var body: some View {
    Group {
      if let url {
        AsyncImage(url: url) { phase in
          if let image = phase.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            BookishRecordIndexPlaceholder(systemImage: placeholderSystemImage)
          }
        }
      } else {
        BookishRecordIndexPlaceholder(systemImage: placeholderSystemImage)
      }
    }
    .frame(width: size, height: size)
    .background(.quaternary, in: .rect(cornerRadius: 6))
    .clipShape(.rect(cornerRadius: 6))
    .accessibilityHidden(true)
  }
}

/// Displays the decorative SF Symbol used when a record has no thumbnail.
private struct BookishRecordIndexPlaceholder: View {
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

#Preview {
  List {
    BookishRecordIndexCell(
      record: BookishRecord(
        kind: BookishRecordKind.book,
        properties: [
          BookishRecordKey.name: .string("The Left Hand of Darkness: A Long Book Title")
        ]),
      layout: nil,
      placeholderSystemImage: "books.vertical"
    )
  }
}
