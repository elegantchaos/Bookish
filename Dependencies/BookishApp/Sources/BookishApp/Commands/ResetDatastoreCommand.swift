// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Icons

/// Removes all records and mutations from the local datastore.
public struct ResetDatastoreCommand<Centre: BookishStorageProvider & BookishStatusReportingProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.reset"

  public init() {
  }

  public func name(centre: Centre) -> String {
    "Reset Bookish Datastore"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("trash")
  }

  public func help(centre: Centre) -> String? {
    "Remove every record and mutation from the datastore."
  }

  public func confirmation(centre: Centre) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Reset Bookish Datastore?",
      cancel: "Cancel",
      message: "This removes every record and mutation from the datastore.",
      confirm: "Reset"
    )
  }

  public func perform(centre: Centre) async throws {
    try await centre.storageService.reset()
    centre.statusReporter.report(message: "Reset datastore")
  }
}
