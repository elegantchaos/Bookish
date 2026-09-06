// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Icons

/// Removes all records and mutations from the local datastore.
public struct ResetDatastoreCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.reset"

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Reset Bookish Datastore"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("trash")
  }

  public func help(centre: BookishHarness) -> String? {
    "Remove every record and mutation from the datastore."
  }

  public func confirmation(centre: BookishHarness) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Reset Bookish Datastore?",
      cancel: "Cancel",
      message: "This removes every record and mutation from the datastore.",
      confirm: "Reset"
    )
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.reset()
  }
}
