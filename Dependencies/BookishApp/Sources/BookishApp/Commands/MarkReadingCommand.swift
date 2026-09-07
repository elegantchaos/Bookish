// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Commands
import Icons

/// Marks the selected record as currently being read.
public struct MarkReadingCommand<Centre: BookishHarnessProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.mark-reading"
  public var shortcut: CommandShortcut? { .init("r", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.harness.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: Centre) -> String {
    "Mark Reading"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("book")
  }

  public func help(centre: Centre) -> String? {
    "Mark the selected record as currently being read."
  }

  public func perform(centre: Centre) async throws {
    await centre.harness.markReading()
  }
}
