// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import BookishImporter
import BookishImporterSamples
import CommandsUI
import Foundation
import Icons

/// Requests a Delicious Library import through the view-owned file picker.
public struct ImportOtherDeliciousLibraryCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.import.delicious-library.other"

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Other…"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import records from another Delicious Library XML export."
  }

  public func perform(centre: BookishHarness) async throws {
    centre.requestDeliciousLibraryImport()
  }
}
