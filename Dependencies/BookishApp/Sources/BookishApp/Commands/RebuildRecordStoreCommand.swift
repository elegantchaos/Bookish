//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

import Foundation
import CommandsUI
import Icons

/// Rebuilds the materialised record projection from stored mutations.
public struct RebuildRecordStoreCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.rebuild-record-store"

  /// Creates the record-store rebuild command.
  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Rebuild Record Store"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("arrow.clockwise")
  }

  public func help(centre: BookishHarness) -> String? {
    "Discard the materialised record store and rebuild it from stored mutations."
  }

  public func confirmation(centre: BookishHarness) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Rebuild Record Store?",
      cancel: "Cancel",
      message: "This discards the materialised record store and rebuilds it from stored mutations.",
      confirm: "Rebuild"
    )
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.rebuildRecordProjection()
  }
}
