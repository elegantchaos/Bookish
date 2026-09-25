// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors reported when an importer finishes without a completion event.
enum BookishImportingError: LocalizedError {
  /// The importer stream ended before reporting a summary.
  case missingCompletion
  case catalogueChanged

  /// Describes the malformed importer stream for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .missingCompletion:
      "The import ended before reporting completion."
    case .catalogueChanged:
      "The catalogue changed during review. Read the import again before applying it."
    }
  }
}
