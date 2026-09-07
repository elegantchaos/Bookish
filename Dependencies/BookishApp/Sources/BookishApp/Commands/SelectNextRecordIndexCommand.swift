// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Selects the next record index in the datastore browser.
public struct SelectNextRecordIndexCommand<Centre: BookishBrowserIndexingProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-index"
  public var shortcut: CommandShortcut? { .init(.rightArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.browserIndexSelectionService.canSelectAnotherRecordIndex ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Next Record Index"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("sidebar.right")
  }

  public func help(centre: Centre) -> String? {
    "Select the next record index in the datastore browser."
  }

  public func perform(centre: Centre) async throws {
    await centre.browserIndexSelectionService.selectNextRecordIndex()
  }
}
