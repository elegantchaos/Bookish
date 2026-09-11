// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import CommandsUI
import Icons

/// Selects a record within the active browser index.
public struct SelectRecordCommand<Centre: BookishNavigationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id: String
  private let recordID: BookishRecordID?

  /// Creates a command that selects a record or restores the index default selection.
  public init(recordID: BookishRecordID?) {
    self.id = "datastore.navigation.select-record.\(recordID?.rawValue ?? "default")"
    self.recordID = recordID
  }

  public func availability(centre: Centre) -> CommandAvailability {
    guard let recordID else {
      return .enabled
    }

    return centre.navigationService.contains(recordID: recordID) ? .enabled : .disabled
  }

  public func name(centre _: Centre) -> String {
    "Select Record"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("book")
  }

  public func help(centre _: Centre) -> String? {
    "Select a record in the active datastore browser index."
  }

  public func perform(centre: Centre) async throws {
    centre.navigationService.select(recordID: recordID)
  }
}
