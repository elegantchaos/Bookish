// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the previous record index in the datastore browser.
public struct SelectPreviousRecordIndexCommand<Centre: BookishBrowserIndexSelectionServiceProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-index"
  public var shortcut: CommandShortcut? { .init(.leftArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.browserIndexSelectionService.canSelectAnotherRecordIndex ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Previous Record Index"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("sidebar.left")
  }

  public func help(centre: Centre) -> String? {
    "Select the previous record index in the datastore browser."
  }

  public func perform(centre: Centre) async throws {
    await centre.browserIndexSelectionService.selectPreviousRecordIndex()
  }
}
