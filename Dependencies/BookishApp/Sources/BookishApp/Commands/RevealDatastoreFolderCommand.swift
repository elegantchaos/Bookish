// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

#if canImport(AppKit)
  import AppKit
#endif

/// Reveals the datastore folder in Finder.
public struct RevealDatastoreFolderCommand<
  Centre: BookishStorageProvider & BookishStatusProvider
>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.reveal-folder"

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    #if canImport(AppKit)
      .enabled
    #else
      .disabled
    #endif
  }

  public func name(centre: Centre) -> String {
    "Reveal Datastore Folder"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("folder")
  }

  public func help(centre: Centre) -> String? {
    "Reveal the local datastore folder in Finder."
  }

  public func perform(centre: Centre) async throws {
    #if canImport(AppKit)
      let url = try centre.storageService.localDatastoreDirectory()
      NSWorkspace.shared.activateFileViewerSelecting([url])
    #else
      centre.statusService.report(
        message: "Reveal datastore folder is unavailable on this platform"
      )
    #endif
  }
}
