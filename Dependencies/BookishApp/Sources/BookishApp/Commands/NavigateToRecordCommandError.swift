// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors reported when a requested record navigation route is unavailable.
public enum NavigateToRecordCommandError: LocalizedError {
  /// The browser cannot yet resolve the most suitable index for a linked record.
  case bestIndexSelectionUnavailable

  /// A user-facing explanation of why the navigation route is unavailable.
  public var errorDescription: String? {
    switch self {
    case .bestIndexSelectionUnavailable:
      "Selecting the best index for a linked record is not available yet."
    }
  }
}
