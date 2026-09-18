// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes the bibliographic fields used by Bookish from a Google Books volume.
struct GoogleBooksVolumeInfo: Codable {
  /// The primary book title.
  let title: String

  /// The optional subtitle.
  let subtitle: String?

  /// The credited contributors.
  let authors: [String]?

  /// The named publisher.
  let publisher: String?

  /// The publication date in Google's supplied precision.
  let publishedDate: String?

  /// The ISBN and other industry identifiers.
  let industryIdentifiers: [GoogleBooksIndustryIdentifier]?

  /// The page count.
  let pageCount: Int?

  /// The cover image links.
  let imageLinks: GoogleBooksImageLinks?

  /// Returns the identifier matching a Google Books identifier type.
  func identifier(ofType type: String) -> String? {
    industryIdentifiers?.first(where: { $0.type == type })?.identifier
  }
}
