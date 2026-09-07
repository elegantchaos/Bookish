// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the next record in the active datastore browser index.
public struct SelectNextRecordCommand<Centre: BookishNavigationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-record"
  public var shortcut: CommandShortcut? { .init(.downArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.navigationService.canSelectAnotherRecord ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Next Record"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("arrow.down")
  }

  public func help(centre: Centre) -> String? {
    "Select the next record in the active datastore browser index."
  }

  public func perform(centre: Centre) async throws {
    centre.navigationService.selectNextRecord()
  }
}
