// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import CommandsUI
import Foundation
import Icons

/// Marks the selected record as currently being read.
public struct MarkReadingCommand<Centre: BookishRecordActionsService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  public let recordID: BookishRecordID?

  public let id = "datastore.mark-reading"
  public var shortcut: CommandShortcut? { .init("r", modifiers: [.command, .shift]) }

  public init(recordID: BookishRecordID? = nil) {
    self.recordID = recordID
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.recordActionsService.canAct(on: recordID) ? .enabled : .disabled
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
    await centre.recordActionsService.markReading(recordID: recordID)
  }
}
