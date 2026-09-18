// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes one industry identifier from a Google Books volume.
struct GoogleBooksIndustryIdentifier: Codable {
  /// Google's identifier classification, such as `ISBN_13`.
  let type: String

  /// The provider's identifier value.
  let identifier: String
}
