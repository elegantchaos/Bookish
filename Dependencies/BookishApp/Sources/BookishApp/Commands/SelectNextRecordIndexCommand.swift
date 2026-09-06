// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the next record index in the datastore browser.
public struct SelectNextRecordIndexCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-index"
  public var shortcut: CommandShortcut? { .init(.rightArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIndexIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishHarness) -> String {
    "Next Record Index"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("sidebar.right")
  }

  public func help(centre: BookishHarness) -> String? {
    "Select the next record index in the datastore browser."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.selectNextRecordIndex()
  }
}
