//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

import Commands
import CommandsUI
import Foundation
import Icons

#if canImport(AppKit)
  import AppKit
#endif

/// Reveals the datastore folder in Finder.
public struct RevealDatastoreFolderCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.reveal-folder"

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    #if canImport(AppKit)
      .enabled
    #else
      .disabled
    #endif
  }

  public func name(centre: BookishHarness) -> String {
    "Reveal Datastore Folder"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("folder")
  }

  public func help(centre: BookishHarness) -> String? {
    "Reveal the local datastore folder in Finder."
  }

  public func perform(centre: BookishHarness) async throws {
    #if canImport(AppKit)
      let url = try centre.localDatastoreDirectory()
      NSWorkspace.shared.activateFileViewerSelecting([url])
      centre.report(message: "Revealed datastore folder")
    #else
      centre.report(
        message: "Reveal datastore folder is unavailable on this platform"
      )
    #endif
  }
}
