// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes the work-level metadata fields selected from an Open Library search.
struct OpenLibrarySearchDocument: Codable {
  /// The stable Open Library work identifier.
  let key: String

  /// The work title.
  let title: String

  /// The credited contributors.
  let authorNames: [String]?

  /// The publishers associated with matching editions.
  let publisherNames: [String]?

  /// The earliest publication year associated with the work.
  let firstPublishedYear: Int?

  /// ISBNs associated with matching editions.
  let isbns: [String]?

  /// The median page count across matching editions.
  let pageCount: Int?

  /// The preferred Open Library cover identifier.
  let coverID: Int?

  /// Maps Open Library's snake-case keys to Swift names.
  enum CodingKeys: String, CodingKey {
    /// The work identifier.
    case key

    /// The title.
    case title

    /// The credited contributors.
    case authorNames = "author_name"

    /// The matching publishers.
    case publisherNames = "publisher"

    /// The earliest publication year.
    case firstPublishedYear = "first_publish_year"

    /// The edition ISBNs.
    case isbns = "isbn"

    /// The median edition page count.
    case pageCount = "number_of_pages_median"

    /// The cover identifier.
    case coverID = "cover_i"
  }

  /// Returns the first normalized ISBN with the requested number of characters.
  func isbn(ofLength length: Int) -> String? {
    isbns?
      .map { $0.filter(\.isNumber) }
      .first(where: { $0.count == length })
  }

  /// Returns the Open Library large-cover URL when the document supplies a cover.
  var coverURL: URL? {
    guard let coverID else { return nil }
    return URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-L.jpg")
  }
}
