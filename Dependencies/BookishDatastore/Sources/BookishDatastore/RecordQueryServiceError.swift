// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Failures reported by a `RecordQueryService`.
public enum RecordQueryServiceError: LocalizedError, Equatable {
  /// The result wasn't created by this service, or has been released.
  case unknownResult

  public var errorDescription: String? {
    switch self {
    case .unknownResult:
      "The query result isn't managed by this query service."
    }
  }
}
