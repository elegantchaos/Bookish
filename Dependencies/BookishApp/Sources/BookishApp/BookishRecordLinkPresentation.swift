// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// The resolved visual metadata shown for a link to a catalogue record.
struct BookishRecordLinkPresentation: Equatable {
  /// The linked record name, falling back to its stable identifier when unnamed.
  let name: String

  /// The linked record's primary image URL, when available.
  let imageURL: URL?

  /// The SF Symbol displayed when the linked record has no image.
  let placeholderSystemImage: String

  /// Creates visual metadata from a materialised linked record.
  init(record: BookishRecord, placeholderSystemImage: String) {
    self.name = record.string(BookishRecordKey.name) ?? record.id.rawValue
    self.imageURL = record.url(BookishRecordKey.image)
    self.placeholderSystemImage = placeholderSystemImage
  }
}
