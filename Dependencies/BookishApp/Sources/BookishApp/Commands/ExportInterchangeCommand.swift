// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Commands
import Icons

/// Exports the materialised records as Bookish interchange JSON.
public struct ExportInterchangeCommand<Centre: BookishDatastoreMaintenanceProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.export.interchange"
  public var shortcut: CommandShortcut? { .init("e", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.datastoreMaintenanceService.hasExportableRecords ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Export Interchange File..."
  }

  public func icon(centre: Centre) -> Icon {
    Icon("square.and.arrow.up")
  }

  public func help(centre: Centre) -> String? {
    "Export the current materialised records as Bookish interchange JSON."
  }

  public func perform(centre: Centre) async throws {
    await centre.datastoreMaintenanceService.requestInterchangeExport()
  }
}
