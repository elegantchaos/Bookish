// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Identifies a metadata lookup provider compiled into Bookish.
public enum BookLookupProviderID: String, Codable, Sendable, Hashable, CaseIterable {
  /// Identifies the deterministic provider used for previews and tests.
  case fake

  /// Identifies the Google Books metadata provider.
  case googleBooks = "google-books"

  /// Identifies the Open Library metadata provider.
  case openLibrary = "open-library"
}
