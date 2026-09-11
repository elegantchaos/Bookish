// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Imports records from a Delicious Library export selected in the system picker.
public struct ImportSelectedDeliciousLibraryCommand<Centre: BookishImportPresentationProvider>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.import.selected-delicious-library"
  private let url: URL

  /// Creates a command for a Delicious Library export selected by the user.
  public init(url: URL) {
    self.url = url
  }

  public func name(centre _: Centre) -> String {
    "Import Selected Delicious Library Export"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre _: Centre) -> String? {
    "Import records from the selected Delicious Library XML export."
  }

  public func perform(centre: Centre) async throws {
    await centre.importPresentation.importDeliciousLibrary(from: url)
  }
}
