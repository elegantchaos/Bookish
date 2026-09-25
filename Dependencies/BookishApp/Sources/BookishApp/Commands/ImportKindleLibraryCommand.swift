import Commands
import CommandsUI
import Icons

/// Opens the picker for a Kindle library database file.
public struct ImportKindleLibraryCommand<Centre: BookishImportingService.Access>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.kindle-library"

  public init() {}

  public func name(centre _: Centre) -> String { "Choose File…" }

  public func icon(centre _: Centre) -> Icon { Icon("books.vertical") }

  public func help(centre _: Centre) -> String? {
    "Choose a Kindle BookData.sqlite database to import."
  }

  public func perform(centre: Centre) async throws {
    centre.importingAPI.requestKindleLibraryImport()
  }
}
