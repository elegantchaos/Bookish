// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors whose meaning is shared by lookup providers.
public enum BookLookupError: LocalizedError, Sendable {
  /// The provider requires configuration that the application did not supply.
  case missingConfiguration

  /// A provider returned a response that cannot be interpreted as book metadata.
  case invalidResponse

  /// A provider returned a non-successful HTTP response.
  case serverError(statusCode: Int, message: String)

  /// A user-facing explanation suitable for a lookup workflow.
  public var errorDescription: String? {
    switch self {
    case .missingConfiguration:
      "This book metadata service has not been configured."
    case .invalidResponse:
      "The book metadata service returned an unreadable response."
    case .serverError(_, let message):
      message
    }
  }
}
