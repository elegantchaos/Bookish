// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Foundation
import Icons

/// Imports records from an interchange file selected in the system picker.
public struct ImportSelectedInterchangeCommand<Centre: BookishImportPresentationProvider>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.import.selected-interchange"
  private let url: URL

  /// Creates a command for an interchange file selected by the user.
  public init(url: URL) {
    self.url = url
  }

  public func name(centre _: Centre) -> String {
    "Import Selected Interchange File"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("square.and.arrow.down")
  }

  public func help(centre _: Centre) -> String? {
    "Import records from the selected Bookish interchange JSON file."
  }

  public func perform(centre: Centre) async throws {
    await centre.importPresentation.importInterchange(from: url)
  }
}
