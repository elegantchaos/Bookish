// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Commands
import Icons

/// Marks the selected record as currently being read.
public struct MarkReadingCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-reading"
  public var shortcut: CommandShortcut? { .init("r", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Mark Reading"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("book")
  }

  public func help(centre: BookishHarness) -> String? {
    "Mark the selected record as currently being read."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.markReading()
  }
}
