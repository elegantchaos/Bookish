// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the previous record in the active datastore browser index.
public struct SelectPreviousRecordCommand: CommandWithUI {
  public typealias Centre = BookishNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-record"
  public var shortcut: CommandShortcut? { .init(.upArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishNavigationService) -> CommandAvailability {
    centre.selectedRecordIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishNavigationService) -> String {
    "Previous Record"
  }

  public func icon(centre: BookishNavigationService) -> Icon {
    Icon("arrow.up")
  }

  public func help(centre: BookishNavigationService) -> String? {
    "Select the previous record in the active datastore browser index."
  }

  public func perform(centre: BookishNavigationService) async throws {
    centre.selectPreviousRecord()
  }
}
