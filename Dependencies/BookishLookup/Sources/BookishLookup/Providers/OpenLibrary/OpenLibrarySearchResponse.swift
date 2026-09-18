// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes the successful portion of an Open Library search response.
struct OpenLibrarySearchResponse: Codable {
  /// The matching work documents returned by Open Library.
  let documents: [OpenLibrarySearchDocument]

  /// Maps Open Library's `docs` member to a Swift-named collection.
  enum CodingKeys: String, CodingKey {
    /// The provider field containing search documents.
    case documents = "docs"
  }

  /// Treats an omitted `docs` member as a successful lookup with no candidates.
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    documents =
      try container.decodeIfPresent([OpenLibrarySearchDocument].self, forKey: .documents) ?? []
  }
}
