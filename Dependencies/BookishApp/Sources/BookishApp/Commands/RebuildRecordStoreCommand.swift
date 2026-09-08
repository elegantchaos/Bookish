// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CommandsUI
import Foundation
import Icons

/// Rebuilds the materialised record projection from stored mutations.
public struct RebuildRecordStoreCommand<Centre: BookishStorageProvider & BookishStatusProvider>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.rebuild-record-store"

  /// Creates the record-store rebuild command.
  public init() {
  }

  public func name(centre: Centre) -> String {
    "Rebuild Record Store"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("arrow.clockwise")
  }

  public func help(centre: Centre) -> String? {
    "Discard the materialised record store and rebuild it from stored mutations."
  }

  public func confirmation(centre: Centre) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Rebuild Record Store?",
      cancel: "Cancel",
      message: "This discards the materialised record store and rebuilds it from stored mutations.",
      confirm: "Rebuild"
    )
  }

  public func perform(centre: Centre) async throws {
    try await centre.storageService.rebuildRecordProjection()
    centre.statusService.report(message: "Rebuilt record store")
  }
}
