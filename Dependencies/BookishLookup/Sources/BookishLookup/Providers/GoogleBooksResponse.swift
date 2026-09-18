// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes the successful portion of a Google Books volumes response.
struct GoogleBooksResponse: Codable {
  /// The matching books returned by Google, or an empty result set.
  let items: [GoogleBooksVolume]

  /// Treats a missing `items` member as a successful lookup with no candidates.
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    items = try container.decodeIfPresent([GoogleBooksVolume].self, forKey: .items) ?? []
  }
}
