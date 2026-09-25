// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Selects the previous record in the active datastore browser index.
public struct SelectPreviousRecordCommand<Centre: BookishNavigationService.Access>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-record"
  public var shortcut: CommandShortcut? { .init(.upArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.navigationAPI.canSelectAnotherRecord ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Previous Record"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("arrow.up")
  }

  public func help(centre: Centre) -> String? {
    "Select the previous record in the active datastore browser index."
  }

  public func perform(centre: Centre) async throws {
    centre.navigationAPI.selectPreviousRecord()
  }
}
