import CommandsUI
import Foundation
import Icons

/// Imports a Kindle database selected in the system picker.
public struct ImportSelectedKindleLibraryCommand<Centre: BookishImportingService.Access>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.import.selected-kindle-library"
  private let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func name(centre _: Centre) -> String { "Import Selected Kindle Database" }

  public func icon(centre _: Centre) -> Icon { Icon("book.closed") }

  public func help(centre _: Centre) -> String? {
    "Import records from the selected Kindle BookData.sqlite database."
  }

  public func perform(centre: Centre) async throws {
    await centre.importingAPI.importKindleLibrary(from: url)
  }
}
