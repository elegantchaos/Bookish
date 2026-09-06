// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the previous record index in the datastore browser.
public struct SelectPreviousRecordIndexCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-index"
  public var shortcut: CommandShortcut? { .init(.leftArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIndexIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishHarness) -> String {
    "Previous Record Index"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("sidebar.left")
  }

  public func help(centre: BookishHarness) -> String? {
    "Select the previous record index in the datastore browser."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.selectPreviousRecordIndex()
  }
}
