// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors raised by Bookish import tools.
public enum BookishImportError: Error, Equatable, LocalizedError {
  /// The source data could not be parsed.
  case invalidSource

  /// The parsed source does not look like the expected provider format.
  case unsupportedSource

  /// The selected importer has not been implemented yet.
  case unavailable(String)

  /// A user-facing explanation of the import failure.
  public var errorDescription: String? {
    switch self {
    case .invalidSource:
      "The import source could not be read."
    case .unsupportedSource:
      "This file is not a supported import source."
    case .unavailable(let message):
      message
    }
  }
}
