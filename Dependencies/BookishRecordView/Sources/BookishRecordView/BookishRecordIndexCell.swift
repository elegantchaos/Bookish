// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation
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
      BookishRecordThumbnail(
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
