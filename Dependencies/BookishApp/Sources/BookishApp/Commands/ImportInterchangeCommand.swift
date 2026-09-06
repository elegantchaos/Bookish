//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

import CommandsUI
import Foundation
import Icons

/// Requests an interchange JSON import through the view-owned file picker.
public struct ImportInterchangeCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.import.interchange"
  public var shortcut: CommandShortcut? {
    .init("i", modifiers: [.command, .shift])
  }

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Import Interchange File..."
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("square.and.arrow.down")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import records from a Bookish interchange JSON file."
  }

  public func perform(centre: BookishHarness) async throws {
    centre.requestInterchangeImport()
  }
}
