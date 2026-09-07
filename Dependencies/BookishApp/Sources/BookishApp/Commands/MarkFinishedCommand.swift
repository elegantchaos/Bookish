// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Marks the selected record as finished.
public struct MarkFinishedCommand<Centre: BookishRecordActionServiceProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.mark-finished"
  public var shortcut: CommandShortcut? {
    .init("f", modifiers: [.command, .shift])
  }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.recordActionService.hasSelectedRecord ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Mark Finished"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("checkmark.circle")
  }

  public func help(centre: Centre) -> String? {
    "Mark the selected record as finished."
  }

  public func perform(centre: Centre) async throws {
    await centre.recordActionService.markFinished()
  }
}
