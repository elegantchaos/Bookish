// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import CommandsUI
import Foundation
import Icons

/// Navigates to a materialised record using the requested browser route.
public struct NavigateToRecordCommand: CommandWithUI {
  /// Controls how navigation reaches a linked record.
  public enum Mode: Sendable {
    /// Pushes the linked record onto the detail navigation stack.
    case push

    /// Selects the linked record when it belongs to the active browser index.
    case currentIndex

    /// Selects the most suitable browser index before showing the linked record.
    case bestIndex
  }

  public typealias Centre = BookishNavigationService
  public typealias ResultType = Void

  public let id: String
  private let recordID: BookishRecordID
  private let mode: Mode

  /// Creates a record navigation command for a specific target.
  public init(recordID: BookishRecordID, mode: Mode = .push) {
    self.id = "datastore.navigation.record.\(recordID.rawValue)"
    self.recordID = recordID
    self.mode = mode
  }

  public func availability(centre: BookishNavigationService)
    -> CommandAvailability
  {
    switch mode {
    case .push:
      .enabled

    case .currentIndex:
      centre.contains(recordID: recordID) ? .enabled : .disabled

    case .bestIndex:
      .disabled
    }
  }

  public func name(centre: BookishNavigationService) -> String {
    "Go to Record"
  }

  public func icon(centre: BookishNavigationService) -> Icon {
    Icon("arrow.right.circle")
  }

  public func help(centre: BookishNavigationService) -> String? {
    "Navigate to the linked record."
  }

  public func perform(centre: BookishNavigationService) async throws {
    switch mode {
    case .push:
      centre.push(recordID: recordID)

    case .currentIndex:
      centre.select(recordID: recordID)

    case .bestIndex:
      throw NavigateToRecordCommandError.bestIndexSelectionUnavailable
    }
  }
}

/// Errors reported when a record navigation route has not yet been implemented.
public enum NavigateToRecordCommandError: LocalizedError {
  /// The browser cannot yet resolve the most suitable index for a linked record.
  case bestIndexSelectionUnavailable

  public var errorDescription: String? {
    switch self {
    case .bestIndexSelectionUnavailable:
      "Selecting the best index for a linked record is not available yet."
    }
  }
}
