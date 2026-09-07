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
public struct NavigateToRecordCommand<Centre: BookishNavigationServiceProvider>: CommandWithUI {
  /// Controls how navigation reaches a linked record.
  public enum Mode: Sendable {
    /// Pushes the linked record onto the detail navigation stack.
    case push

    /// Selects the linked record when it belongs to the active browser index.
    case currentIndex

    /// Selects the most suitable browser index before showing the linked record.
    case bestIndex
  }

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

  public func availability(centre: Centre)
    -> CommandAvailability
  {
    switch mode {
    case .push:
      .enabled

    case .currentIndex:
      centre.navigationService.contains(recordID: recordID) ? .enabled : .disabled

    case .bestIndex:
      .disabled
    }
  }

  public func name(centre: Centre) -> String {
    "Go to Record"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("arrow.right.circle")
  }

  public func help(centre: Centre) -> String? {
    "Navigate to the linked record."
  }

  public func perform(centre: Centre) async throws {
    switch mode {
    case .push:
      centre.navigationService.push(recordID: recordID)

    case .currentIndex:
      centre.navigationService.select(recordID: recordID)

    case .bestIndex:
      throw NavigateToRecordCommandError.bestIndexSelectionUnavailable
    }
  }
}
