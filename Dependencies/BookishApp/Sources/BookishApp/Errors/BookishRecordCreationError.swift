// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Explains why a New command cannot find a browser destination.
enum BookishRecordCreationError: LocalizedError {
  /// No library index is configured to show the requested type.
  case noIndex(BookishNewRecordType)

  /// The error shown by the app's command failure reporter.
  var errorDescription: String? {
    switch self {
    case .noIndex(let type): "No index can show a new \(type.menuName.lowercased())."
    }
  }
}
