// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Marks the selected record as finished.
public struct MarkFinishedCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-finished"
  public var shortcut: CommandShortcut? {
    .init("f", modifiers: [.command, .shift])
  }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Mark Finished"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("checkmark.circle")
  }

  public func help(centre: BookishHarness) -> String? {
    "Mark the selected record as finished."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.markFinished()
  }
}
