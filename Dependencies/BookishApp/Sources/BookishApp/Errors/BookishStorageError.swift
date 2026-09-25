// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors reported when a datastore operation requires an unavailable store.
enum BookishStorageError: LocalizedError {
  /// The datastore has not completed loading.
  case notLoaded
  /// A bundled seed resource could not be found.
  case missingSeedResource(String)

  /// Describes the unavailable datastore for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .notLoaded: "The datastore has not been loaded."
    case .missingSeedResource(let name):
      "The bundled \(name) seed resource is missing."
    }
  }
}
