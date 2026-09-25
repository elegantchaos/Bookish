// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Selects the previous record index in the datastore browser.
public struct SelectPreviousRecordIndexCommand<Centre: BookishNavigationService.Access>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-index"
  public var shortcut: CommandShortcut? { .init(.leftArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.navigationAPI.canSelectAnotherRecordIndex ? .enabled : .disabled
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
    try await centre.navigationAPI.selectPreviousRecordIndex()
  }
}
