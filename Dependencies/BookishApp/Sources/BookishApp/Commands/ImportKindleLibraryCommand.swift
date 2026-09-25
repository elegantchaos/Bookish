import Commands
import CommandsUI
import Icons

/// Requests access to Kindle's local library database.
public struct ImportKindleLibraryCommand<Centre: BookishImportingService.Provider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.import.kindle-library"

  public init() {}

  public func name(centre _: Centre) -> String { "Import Kindle Library…" }

  public func icon(centre _: Centre) -> Icon { Icon("books.vertical") }

  public func help(centre _: Centre) -> String? {
    "Import new Kindle titles from the local Kindle for Mac database."
  }

  public func perform(centre: Centre) async throws {
    centre.importingService.requestKindleLibraryImport()
  }
}
