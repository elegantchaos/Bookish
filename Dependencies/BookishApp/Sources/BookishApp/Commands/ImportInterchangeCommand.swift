// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CommandsUI
import Foundation
import Icons

/// Requests an interchange JSON import through the view-owned file picker.
public struct ImportInterchangeCommand<Centre: BookishHarnessProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.interchange"
  public var shortcut: CommandShortcut? {
    .init("i", modifiers: [.command, .shift])
  }

  public init() {
  }

  public func name(centre: Centre) -> String {
    "Import Interchange File..."
  }

  public func icon(centre: Centre) -> Icon {
    Icon("square.and.arrow.down")
  }

  public func help(centre: Centre) -> String? {
    "Import records from a Bookish interchange JSON file."
  }

  public func perform(centre: Centre) async throws {
    centre.harness.requestInterchangeImport()
  }
}
