// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors reported when a harness operation requires unavailable local state.
enum BookishHarnessError: LocalizedError {
  /// The datastore has not completed loading.
  case notLoaded

  /// A required bundled seed resource is unavailable.
  case missingSeedResource(String)

  /// A user-facing explanation of the harness error.
  var errorDescription: String? {
    switch self {
    case .notLoaded:
      "The datastore is not loaded."

    case .missingSeedResource(let name):
      "The bundled seed resource '\(name).bookish.json' is missing."
    }
  }
}
