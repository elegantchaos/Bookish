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
public struct ImportOtherDeliciousLibraryCommand<Centre: BookishImportPresentationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.delicious-library.other"

  public init() {
  }

  public func name(centre: Centre) -> String {
    "Other…"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: Centre) -> String? {
    "Import records from another Delicious Library XML export."
  }

  public func perform(centre: Centre) async throws {
    centre.importPresentation.requestDeliciousLibraryImport()
  }
}
