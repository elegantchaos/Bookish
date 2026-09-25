import CommandsUI
import Icons

/// Imports the bundled synthetic Kindle database.
public struct ImportKindleLibrarySampleCommand<Centre: BookishImportingService.Access>:
  CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.import.kindle-library.sample"

  public init() {}

  public func name(centre _: Centre) -> String { "Test Fixture" }

  public func icon(centre _: Centre) -> Icon { Icon("book.closed") }

  public func help(centre _: Centre) -> String? {
    "Import the bundled synthetic Kindle database."
  }

  public func perform(centre: Centre) async throws {
    await centre.importingAPI.importKindleLibrarySample()
  }
}
