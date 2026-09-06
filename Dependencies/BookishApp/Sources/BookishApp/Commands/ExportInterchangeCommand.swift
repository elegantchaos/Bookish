//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

import Foundation
import CommandsUI
import Commands
import Icons

/// Exports the materialised records as Bookish interchange JSON.
public struct ExportInterchangeCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.export.interchange"
  public var shortcut: CommandShortcut? { .init("e", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIDs.isEmpty ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Export Interchange File..."
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("square.and.arrow.up")
  }

  public func help(centre: BookishHarness) -> String? {
    "Export the current materialised records as Bookish interchange JSON."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.requestInterchangeExport()
  }
}
